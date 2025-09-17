# Myorg Myproject Ansible Project

## Included content/ Directory Structure

The directory structure follows best practices recommended by the Ansible
community. Feel free to customize this template according to your specific
project requirements.

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

### Running the Ansible Playbook

To deploy the NFS server and client configuration:

```bash
ansible-playbook -i inventory/hosts.yml nfs-server-client.yml
```

### Running Tests

To run pytest tests for the project:

```bash
pytest -v tests/test_nfs_clients.py --hosts='ansible://nfs_clients'
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
