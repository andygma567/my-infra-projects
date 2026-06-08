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
OpenTofu (disposable)          Ansible (deliverable)
NFS share + droplets    -->    playbooks/slurmdbd.yml, slurm.yml
        |
        '--> build/hosts.yml
```

- `tofu/` — provisions NFS + droplets, generates `build/hosts.yml`
- `ansible/` — SLURM playbooks, group vars, and testinfra tests
- `scripts/` — wrappers for provision → configure → test → destroy

The network is referenced, not created — see [docs/networking.md](docs/networking.md).

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

### Configure and scale

[`scripts/configure.sh`](scripts/configure.sh) defaults to `install`. It also
supports `uninstall` and `scale` (add or remove compute nodes). See
[docs/operations.md](docs/operations.md) for subcommand details and individual
Ansible playbook usage.

### Running tests

```bash
./scripts/test.sh

# Or a single test file
cd ansible
pytest -v tests/test_slurm.py
```

## Further docs

- [docs/networking.md](docs/networking.md) — why the VPC is referenced, not managed
- [docs/operations.md](docs/operations.md) — configure/scale, uninstall, and running playbooks directly
- [docs/ansible-slurm.md](docs/ansible-slurm.md) — `galaxyproject.slurm` role and known upstream issues
