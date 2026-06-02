#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Install Ansible dependencies (collections + roles).
ansible-galaxy collection install -r "${ROOT}/ansible/requirements.yml" -p "${ROOT}/ansible/collections"
ansible-galaxy role install -r "${ROOT}/ansible/requirements.yml" -p "${ROOT}/ansible/roles"

# Run from the ansible/ directory so ansible.cfg resolves the inventory
# (./inventory for group_vars + ../build/hosts.yml for the Tofu-generated hosts).
cd "${ROOT}/ansible"

ansible all -m ping

# The shared filesystem is provisioned by OpenTofu (managed NFS) and mounted via
# cloud-init before this runs, so Ansible only configures Slurm.
ansible-playbook playbooks/slurmdbd.yml
ansible-playbook playbooks/slurm.yml
