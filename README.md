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
VPC                                          playbooks/slurmdbd.yml
managed NFS share  --(cloud-init mount)-->   playbooks/slurm.yml
head + compute droplets
        |
        '--> build/hosts.yml (single generated inventory)
```

- `tofu/` - provisions the VPC, the managed NFS share, and the droplets, and
  generates the Ansible inventory at `build/hosts.yml` from `tofu/hosts.tftpl`.
- `ansible/` - the SLURM playbooks (`slurmdbd.yml`, `slurm.yml`), group vars, and
  testinfra tests. `ansible/ansible.cfg` combines `inventory/` (group vars) with
  the generated `../build/hosts.yml` (hosts).
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
# 1. Provision test infra: VPC + managed NFS share + droplets (generates build/hosts.yml)
./scripts/up.sh

# 2. Configure SLURM (slurmdbd -> slurm). The shared filesystem is already mounted.
./scripts/configure.sh

# 3. Run the testinfra test subset to validate the result
./scripts/test.sh

# 4. Destroy the test infrastructure when done
./scripts/destroy.sh
```

### Teardown gotchas (`destroy.sh`)

`scripts/destroy.sh` can fail or hang for two reasons that are **not** bugs in
this repo — they're rough edges in DigitalOcean's managed NFS (a new product)
and a hard rule about default VPCs. Both are recoverable with local
`tofu state rm` commands (these only edit local state and never touch real
infrastructure).

#### 1. NFS detach is slow and can time out

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
attachment from state and re-run destroy:

```bash
cd tofu
tofu state rm digitalocean_nfs_attachment.shared
cd .. && ./scripts/destroy.sh   # now deletes the share + VPC
```

#### 2. The VPC may be a default VPC and cannot be deleted

DigitalOcean requires exactly one **default VPC per region**, and default VPCs
**cannot be deleted** (the API returns `403 Can not delete default VPCs`). If
`slurm-dev-vpc` was auto-promoted to the region default (happens when the region
has no other default at creation time), `destroy` will fail on it:

```
Error: DELETE .../v2/vpcs/<id>: 403 ... Can not delete default VPCs
```

An empty VPC is **free** (you only pay for resources *inside* it, which are
already gone), so the simplest fix is to stop tracking it:

```bash
cd tofu
tofu state rm digitalocean_vpc.slurm_vpc   # VPC stays on DO as the free region default
```

After this, `tofu state list` is empty and `destroy.sh` reports a clean run.

> Tip: VPCs live under **Networking → VPC** in the DO console (not the
> **Domains** tab), in case you go looking for the leftover network.

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
```

(`playbooks/docker.yml` is still available but is no longer part of the default
deliverable path.)

### Running tests

Tests use testinfra to verify the playbook results against the live inventory.
`scripts/test.sh` runs a curated subset matching the SLURM deliverable plus the
managed shared filesystem:

```bash
# Curated subset (from the ansible/ directory)
./scripts/test.sh

# Or a single test file
cd ansible
pytest -v tests/test_slurm.py
```

## Testing philosophy

- **Ansible playbooks are tested**: testinfra validates SLURM services
  (`slurmctld`, `slurmd`, `slurmdbd`) and that the shared filesystem is mounted.
- **OpenTofu code is NOT tested**: it exists only as disposable test scaffolding.
- **Cloud simulates the cluster**: the VPC + managed NFS share mirror the
  production topology (existing shared filesystem) so the playbooks behave the
  same way in both places.
