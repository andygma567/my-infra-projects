# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This repository is a **development environment for creating and testing Ansible playbooks** intended for on-premises SLURM cluster management. It uses OpenTofu (Terraform fork) to provision temporary test infrastructure on DigitalOcean that mimics an on-prem environment, then applies Ansible playbooks to configure SLURM, NFS, and Docker services.

**Purpose**: Develop and validate Ansible playbooks in a cloud environment before deploying them to production on-premises SLURM clusters.

**Architecture**: The project creates a head node (controller + NFS server + database) and multiple compute nodes in an isolated VPC to simulate an on-prem network topology.

## Architecture

### Infrastructure Layer (OpenTofu)
- **Location**: `tofu/` directory
- **Purpose**: Provisions DigitalOcean droplets, VPC network, and generates Ansible inventory
- **Key files**:
  - `main.tf`: Defines VPC, head node, compute nodes, and inventory generation
  - `inventory.tftpl`: Template that generates `build/inventory.ini` with host groups
  - `providers.tf`: Configures DigitalOcean provider
  - `variables.tf`: Defines configurable parameters (region, sizes, counts, etc.)

### Configuration Layer (Ansible)
- **Location**: `ansible/` directory
- **Purpose**: Configures NFS, Docker, SLURM database, and SLURM cluster
- **Inventory**: Auto-generated at `build/inventory.ini` by OpenTofu (not manually maintained)
- **Config**: `ansible.cfg` points to `../build/inventory.ini`
- **Key playbooks** (in `ansible/playbooks/`):
  - `nfs.yml`: Sets up NFS server on head node, mounts on compute nodes
  - `docker.yml`: Installs Docker on nodes
  - `slurmdbd.yml`: Configures SLURM database daemon
  - `slurm.yml`: Configures SLURM controller and execution nodes
- **Group variables**: `ansible/group_vars/` contains configuration for different host groups (nfs_servers, nfs_clients, slurmctld, slurmnodes, slurmdbdservers)
- **Dependencies**: `ansible/requirements.yml` defines required Ansible Galaxy collections and roles (geerlingguy.nfs, community.general, ansible.posix)

### Environment Configuration
- **Location**: `envs/{dev,demo}/` directories
- **Purpose**: Environment-specific overrides
- **Files**:
  - `tofu.tfvars`: OpenTofu variables (region, cluster_name, node sizes, ssh_key_ids, compute_node_count)
  - `ansible.extra.yml`: Optional Ansible variable overrides (passed via `-e` flag)

### Host Groups (in generated inventory)
The OpenTofu template creates these groups:
- `nfs_servers`: Head node (exports /srv and /scratch)
- `nfs_clients`: All compute nodes (mount NFS shares)
- `slurmctld`: Head node (SLURM controller)
- `slurmnodes`: All compute nodes (SLURM execution hosts)
- `slurmdbdservers`: Head node (SLURM database)
- `head_nodes`, `compute_nodes`: Convenience groups

## Common Commands

### Full Workflow (Provision → Configure → Test → Destroy)

```bash
# Provision infrastructure (uses envs/{env}/tofu.tfvars)
./scripts/up.sh dev

# Configure all services (NFS → Docker → SlurmDBD → Slurm)
./scripts/configure.sh dev

# Run all tests
./scripts/test.sh

# Destroy infrastructure
./scripts/destroy.sh dev
```

### OpenTofu Commands

```bash
cd tofu

# Initialize
tofu init

# Plan changes
tofu plan -var-file="../envs/dev/tofu.tfvars"

# Apply (creates infrastructure + generates build/inventory.ini)
tofu apply -var-file="../envs/dev/tofu.tfvars"

# Destroy
tofu destroy -var-file="../envs/dev/tofu.tfvars"
```

### Ansible Commands

All commands run from project root and use the generated inventory:

```bash
# Install dependencies
ansible-galaxy collection install -r ansible/requirements.yml -p ansible/collections

# Test connectivity
ansible -i build/inventory.ini all -m ping

# Run individual playbooks
ansible-playbook -i build/inventory.ini ansible/playbooks/nfs.yml
ansible-playbook -i build/inventory.ini ansible/playbooks/docker.yml
ansible-playbook -i build/inventory.ini ansible/playbooks/slurmdbd.yml
ansible-playbook -i build/inventory.ini ansible/playbooks/slurm.yml

# With environment-specific overrides
ansible-playbook -i build/inventory.ini ansible/playbooks/nfs.yml -e @envs/dev/ansible.extra.yml

# Run against specific host groups
ansible-playbook -i build/inventory.ini ansible/playbooks/nfs.yml --limit nfs_servers
```

### Testing Commands

```bash
# Run all tests (from project root)
pytest -q tests

# Run specific test file
pytest -v tests/test_nfs.py

# Run with testinfra for specific host groups
pytest -v tests/test_nfs.py --hosts='ansible://nfs_clients'
```

**Testing Strategy**: Tests use testinfra to validate Ansible playbook results against the generated inventory in `build/inventory.ini`. Tests focus on verifying the configuration state of services (NFS mounts, Docker installation, SLURM services) rather than testing the OpenTofu infrastructure code itself. The OpenTofu code is intentionally not tested as it exists only to provide a disposable test environment.

## Development Workflow Notes

1. **Inventory Management**: Never manually edit `build/inventory.ini` - it is auto-generated by OpenTofu. To change inventory structure, modify `tofu/inventory.tftpl`.

2. **Environment Variables**: When adding new OpenTofu variables, update both `tofu/variables.tf` (with defaults) and environment-specific `envs/{env}/tofu.tfvars` files.

3. **Configuration Order**: The `configure.sh` script runs playbooks in dependency order:
   - NFS first (shared storage needed by SLURM)
   - Docker second
   - SlurmDBD third (database must run before controller)
   - SLURM last (requires database and NFS)

4. **Ansible Collections**: Before running playbooks for the first time or after updating `ansible/requirements.yml`, install collections with `ansible-galaxy collection install`.

5. **SSH Keys**: Ensure your DigitalOcean SSH key IDs are configured in `envs/{env}/tofu.tfvars` under `ssh_key_ids` before provisioning.

6. **Build Directory**: The `build/` directory is gitignored and contains only generated files (inventory). It's created automatically by OpenTofu.

## Python Testing Environment

Tests use pytest with testinfra plugin. The project uses a Python virtual environment (`.venv/`) with required testing dependencies.

## Development Philosophy

- **OpenTofu is disposable infrastructure**: The cloud VMs exist only to test Ansible playbooks. No tests are written for OpenTofu code.
- **Ansible playbooks are the deliverable**: These playbooks will be used on production on-premises SLURM clusters, so they must be thoroughly tested with testinfra.
- **Cloud mirrors on-prem**: The DigitalOcean VPC setup simulates an on-premises network topology to ensure playbooks behave correctly in the target environment.
