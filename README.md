# SLURM Cluster Ansible Development Environment

## Purpose

This repository is a **development and testing environment for the Ansible
playbooks that configure SLURM** on HPC clusters. It uses OpenTofu to provision
disposable test VMs on DigitalOcean that simulate a bare-metal cluster, so the
playbooks can be developed and validated before running them against the real
on-premises cluster.

**Key principle:** The OpenTofu infrastructure is disposable test scaffolding.
The **Ansible SLURM playbooks are the actual deliverable**.

### Shared filesystem

The production cluster already has a shared filesystem (NFS), so Ansible does
**not** set one up. To mirror that in the test environment, OpenTofu provisions a
**DigitalOcean managed Network File Storage** share and mounts it on every node
via cloud-init *before* Ansible runs. As a result, the playbooks only configure
SLURM and assume the shared filesystem already exists.

## Architecture

```
Infrastructure (OpenTofu, disposable)        Deliverable (Ansible)
-------------------------------------        ---------------------
region default VPC (referenced, not made)    playbooks/slurmdbd.yml
managed NFS share  --(cloud-init mount)-->   playbooks/slurm.yml
head + compute droplets
        |
        '--> build/hosts.yml (single generated inventory)
```

- `tofu/` - provisions the managed NFS share and the droplets, and generates the
  Ansible inventory at `build/hosts.yml` from `tofu/hosts.tftpl`. The network is
  **not** provisioned: `tofu/main.tf` references the region's existing default
  VPC via a `data` source (see "Networking" below), so the disposable
  create/destroy cycle never touches a VPC.
- `ansible/` - the SLURM playbooks (`slurmdbd.yml`, `slurm.yml`, `uninstall.yml`),
  group vars, and testinfra tests. `ansible/ansible.cfg` combines `inventory/`
  (group vars) with the generated `../build/hosts.yml` (hosts).
- `scripts/` - thin wrappers for the provision -> configure -> test -> destroy
  workflow.
- `tofu/terraform.tfvars` - OpenTofu variables (auto-loaded by `tofu apply`).

## Prerequisites

- A DigitalOcean API token exported as `DIGITALOCEAN_TOKEN`.
- An SSH key registered in DigitalOcean (referenced by `tofu/main.tf`).
- OpenTofu, Ansible, and the Python test dependencies (`pytest`, `pytest-testinfra`).
- **Region:** managed Network File Storage is GA only in `atl1`, `nyc2`, and
  `ams3`, so `region` in your tfvars must be one of these. The default is `nyc2`.

## Usage

### Quick start workflow

```bash
# 1. Provision test infra: managed NFS share + droplets in the region's default
#    VPC (generates build/hosts.yml)
./scripts/up.sh

# 2. Configure SLURM (slurmdbd -> slurm). The shared filesystem is already mounted.
./scripts/configure.sh install

# 3. Run the testinfra test subset to validate the result
./scripts/test.sh

# 4. Destroy the test infrastructure when done
./scripts/destroy.sh
```

### Networking: the VPC is referenced, not managed

`tofu/main.tf` does **not** create a VPC. Instead it looks up the region's
existing **default** VPC via a data source:

```hcl
data "digitalocean_vpc" "slurm_vpc" {
  region = var.region
}
```

This is deliberate. DigitalOcean requires exactly one **default VPC per region**
and **default VPCs cannot be deleted** (`403 Can not delete default VPCs`). A
dedicated VPC created by `apply` gets auto-promoted to the region default when no
other default exists, which then breaks the disposable lifecycle in two ways:

- **`destroy` fails** with `403 ... Can not delete default VPCs`, and
- after dropping it from state, the **next `apply` fails** with
  `422 ... a VPC with the same name already exists`.

Referencing the always-present default VPC sidesteps both: the droplets and NFS
share are placed in it, but `apply` never creates it and `destroy` never deletes
it. Trade-off: the test nodes share the region's default VPC rather than a
dedicated isolated network with a custom IP range — fine for disposable test
scaffolding.

> **Migrating from the old resource-based config?** If a previous version managed
> `digitalocean_vpc.slurm_vpc`, drop it from state once (this only edits local
> state; the VPC itself is untouched and stays as the free region default):
>
> ```bash
> cd tofu
> tofu state rm digitalocean_vpc.slurm_vpc   # ignore if it's already absent
> ```
>
> VPCs live under **Networking → VPC** in the DO console (not the **Domains** tab).

### Teardown gotcha (`destroy.sh`): NFS detach is slow and can time out

Destroying `digitalocean_nfs_attachment.shared` calls DigitalOcean's
*asynchronous* "detach share from VPC" operation. The provider polls for
completion with an **internal, hardcoded ~5-minute timeout** that a
`timeouts { delete = "..." }` block **cannot** override. If DO takes longer than
that, you'll see:

```
Error: Error detaching share from vpc after retry timeout:
  ... timeout waiting for NFS detach to complete
```

The detach usually *does* finish on DO's side moments later (the share shows as
`Detached` / `INACTIVE` in the UI). But because the attachment is still in
OpenTofu state, the next `destroy` tries to detach it again and hits a catch-22:

```
400 ... share must be active to detach
```

**Workaround** — once the share shows `Detached` in the DO UI, drop the stale
attachment from state and re-run destroy (this only edits local state and never
touches real infrastructure):

```bash
cd tofu
tofu state rm digitalocean_nfs_attachment.shared
cd .. && ./scripts/destroy.sh   # now deletes the share; the VPC is left alone
```

### Configure script: install, uninstall, and scale

[`scripts/configure.sh`](scripts/configure.sh) is the main entrypoint for Slurm
lifecycle on the inventory (bare metal or test VMs). It defaults to `install`.

```bash
# Deploy (same as ./scripts/configure.sh with no subcommand)
./scripts/configure.sh install

# Full purge: Slurm, munge, MariaDB, configs, and /etc/hosts entries
./scripts/configure.sh uninstall          # prompts for confirmation

# Scale up: add hosts to slurmexechosts in inventory, then reconcile
./scripts/configure.sh scale

# Scale down: drain nodes first, then purge Slurm on removed hosts only
./scripts/configure.sh scale --remove slurm-dev-compute-02
# Edit inventory to drop those hosts from slurmexechosts, then:
./scripts/configure.sh scale
```

**Scale-down assumptions:** nodes are already drained and have no running jobs.
`scale --remove` does not edit inventory automatically; remove hosts from
`slurmexechosts` (and `compute_nodes`) in `build/hosts.yml` or your static
inventory, then run `scale` again to regenerate `slurm.conf` on the cluster.

Uninstall removes only Slurm software. It does not destroy DigitalOcean droplets
(use `./scripts/destroy.sh`) or unmount the shared NFS share.

### Running individual Ansible playbooks

Run from the `ansible/` directory so `ansible.cfg` resolves the inventory
(`./inventory` for group vars + `../build/hosts.yml` for hosts):

```bash
cd ansible
ansible-galaxy collection install -r requirements.yml -p collections
ansible-galaxy role install -r requirements.yml -p roles

ansible all -m ping
ansible-playbook playbooks/slurmdbd.yml
ansible-playbook playbooks/slurm.yml
ansible-playbook playbooks/uninstall.yml   # full purge; use -e purge_db=false for partial
```

### Running tests

Tests use testinfra to verify the playbook results against the live inventory.
All checks run from the controller (head node), so the suite cost is independent
of the number of compute nodes. `scripts/test.sh` runs the SLURM deliverable
subset:

```bash
# Curated subset (from the ansible/ directory)
./scripts/test.sh

# Or a single test file
cd ansible
pytest -v tests/test_slurm.py
```