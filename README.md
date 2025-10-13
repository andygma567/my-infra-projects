# SLURM Cluster Ansible Development Environment

## Purpose

This repository is a **development and testing environment for Ansible playbooks** that configure on-premises SLURM HPC clusters. It uses OpenTofu to provision temporary test VMs on DigitalOcean that simulate an on-prem network, allowing safe development and validation of Ansible playbooks before deploying to production.

**Key Principle**: The OpenTofu infrastructure is disposable test scaffolding. The Ansible playbooks are the actual deliverable for production use.

## Directory Structure

The directory structure follows best practices recommended by the Ansible
community.

```
 ansible-project/
 |── .devcontainer/
 |    └── docker/
 |        └── devcontainer.json
 |    └── podman/
 |        └── devcontainer.json
 |    └── devcontainer.json
 |── .github/
 |    └── workflows/
 |        └── tests.yml
 |    └── ansible-code-bot.yml
 |── .vscode/
 |    └── extensions.json
 |── collections/
 |   └── requirements.yml
 |   └── ansible_collections/
 |       └── project_org/
 |           └── project_repo/
 |               └── README.md
 |               └── roles/sample_role/
 |                         └── README.md
 |                         └── tasks/main.yml
 |── inventory/
 |   |── hosts.yml
 |   |── argspec_validation_inventory.yml
 |   └── groups_vars/
 |   └── host_vars/
 |── ansible-navigator.yml
 |── ansible.cfg
 |── devfile.yaml
 |── linux_playbook.yml
 |── network_playbook.yml
 |── README.md
 |── site.yml
```

## Usage

### Quick Start Workflow

```bash
# 1. Provision test VMs on DigitalOcean (creates build/inventory.ini)
./scripts/up.sh dev

# 2. Run all Ansible playbooks (NFS → Docker → SlurmDBD → Slurm)
./scripts/configure.sh dev

# 3. Run testinfra tests to validate configuration
./scripts/test.sh

# 4. Destroy test infrastructure when done
./scripts/destroy.sh dev
```

### Running Individual Ansible Playbooks

All playbooks use the auto-generated inventory at `build/inventory.ini`:

```bash
ansible-playbook -i build/inventory.ini ansible/playbooks/nfs.yml
ansible-playbook -i build/inventory.ini ansible/playbooks/docker.yml
ansible-playbook -i build/inventory.ini ansible/playbooks/slurmdbd.yml
ansible-playbook -i build/inventory.ini ansible/playbooks/slurm.yml
```

### Running Tests

Tests use testinfra to verify Ansible playbook results:

```bash
# Run all tests
pytest -q tests

# Run specific test file
pytest -v tests/test_nfs.py --hosts='ansible://nfs_clients'
```

## Compatible with Ansible-lint

Tested with ansible-lint >=24.2.0 releases and the current development version
of ansible-core.

## Troubleshooting NFS Permission Issues

### Problem: Permission Denied on NFS Client

If you encounter "Permission denied" errors when trying to write to NFS mounted directories as root, this is likely due to **root squashing** - a security feature where NFS maps the root user (UID 0) on the client to an unprivileged user on the server.

### Root Cause

By default, NFS exports enable root squashing for security. In the current configuration:
- `/home` export: Has root squashing enabled (secure but may cause permission issues for root)
- `/scratch` export: Has `no_root_squash` option (allows root access)

### Solutions

**Option 1: Disable root squashing (less secure)**

Update `inventory/group_vars/nfs_servers.yml` to add `no_root_squash` to the `/home` export:

```yaml
nfs_exports:
  - "/home    *(rw,sync,no_subtree_check,no_root_squash)"
  - "/scratch *(rw,async,no_subtree_check,no_root_squash)"
```

**Option 2: Use non-root user (more secure - recommended)**

Test operations with a regular user instead of root:

```bash
sudo useradd testuser
sudo su - testuser
echo "test content" | tee /mnt/nfs/home/test_file.txt
```

After making changes to exports, re-run the playbook to apply the new configuration:

```bash
ansible-playbook nfs-server-client.yml
```

## Testing Philosophy

- **Ansible playbooks are tested**: Testinfra validates service configuration (NFS mounts, SLURM services, Docker)
- **OpenTofu code is NOT tested**: The infrastructure provisioning exists only as disposable test scaffolding
- **Cloud simulates on-prem**: VPC setup mirrors on-premises network topology for realistic testing
