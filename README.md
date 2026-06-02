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
