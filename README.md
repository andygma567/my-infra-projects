# SLURM Cluster Ansible Development Environment

## Purpose

This repository provides **Ansible playbooks that configure SLURM** on HPC
clusters. Run them directly against any bare-metal inventory — no DigitalOcean or
OpenTofu required.

**Key principle:** The **Ansible SLURM playbooks are the deliverable**. The
OpenTofu stack in `tofu/` is optional, disposable test scaffolding that provisions
throwaway DigitalOcean VMs so you can develop and validate before deploying to
production.

The playbooks assume a shared filesystem (NFS) already exists and do not set one
up; if you need to create one, Jeff Geerling's open-source
[`geerlingguy.nfs`](https://github.com/geerlingguy/ansible-role-nfs) role can do
it.

## Layout

- `ansible/` — SLURM playbooks, group vars, and testinfra tests (the deliverable)
- `tofu/` — optional DigitalOcean test infra; generates `build/hosts.ini`
- `scripts/` — wrappers for configure, test, and (optionally) provision/destroy

The network is referenced, not created — see [docs/networking.md](docs/networking.md).

## Environment setup

### Python dependencies

Primary (recommended):

```bash
uv sync
```

Fallback (installs runtime + dev deps from [pyproject.toml](pyproject.toml)):

```bash
python3.11 -m venv .venv
source .venv/bin/activate
pip install -e . --group dev
```

Requires Python 3.11+ and pip 25.1+ (for `--group dev`).

### Ansible Galaxy dependencies

The playbooks require the `community.mysql` collection and the
`galaxyproject.slurm` role, pinned in
[ansible/requirements.yml](ansible/requirements.yml).

[`scripts/configure.sh`](scripts/configure.sh) installs these automatically on
each run. To install manually:

```bash
ansible-galaxy collection install -r ansible/requirements.yml -p ansible/collections
ansible-galaxy role install -r ansible/requirements.yml -p ansible/roles
```

## Quick start — Ansible on bare metal

1. **Create your inventory.** Copy
   [ansible/inventory.example.ini](ansible/inventory.example.ini) as a starting
   point and list your node IPs under `slurmservers`, `slurmexechosts`, and
   `slurmdbdservers`. Connection defaults (`ansible_user`, SSH key, etc.) live in
   [ansible/inventory/group_vars/all.yml](ansible/inventory/group_vars/all.yml),
   so the inventory file stays a clean list of IPs.

   Point Ansible at your file by updating `inventory` in
   [ansible/ansible.cfg](ansible/ansible.cfg), or place it at
   `ansible/inventory/hosts.ini`.

2. **Configure SLURM** (slurmdbd → slurm). `install` is the default:

   ```bash
   ./scripts/configure.sh
   ```

   To remove Slurm, munge, and MariaDB from the cluster:

   ```bash
   ./scripts/configure.sh uninstall
   ```

3. **Validate** with the testinfra suite:

   ```bash
   ./scripts/test.sh
   ```

## Optional — OpenTofu test infra on DigitalOcean

Use this path only if you want disposable VMs to test or develop the playbooks
without a real cluster.

**Prerequisites:**

- DigitalOcean API token exported as `DIGITALOCEAN_TOKEN`
- An SSH key registered in DigitalOcean (referenced by `tofu/main.tf`)
- OpenTofu installed
- **Region:** managed Network File Storage is GA only in `atl1`, `nyc2`, and
  `ams3` (default: `nyc2`)

```bash
# Provision test infra (generates build/hosts.ini)
./scripts/up.sh

# Configure and test — same as bare metal
./scripts/configure.sh install
./scripts/test.sh

# Tear down when done
./scripts/destroy.sh
```

### Teardown note (`destroy.sh`)

NFS detach on DigitalOcean can hit a hardcoded ~5-minute provider timeout. If
destroy fails, wait until the share shows `Detached` in the DO UI, then:

```bash
cd tofu && tofu state rm digitalocean_nfs_attachment.shared
cd .. && ./scripts/destroy.sh
```

## Configure and scale

[`scripts/configure.sh`](scripts/configure.sh) defaults to `install`. It also
supports `uninstall` and `scale` (add or remove compute nodes). See
[docs/operations.md](docs/operations.md) for subcommand details and running
playbooks directly.

## Running tests

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
