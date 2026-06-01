#!/usr/bin/env bash
set -euo pipefail
ENV="${1:-dev}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Install Ansible dependencies (collections + roles).
ansible-galaxy collection install -r "${ROOT}/ansible/requirements.yml" -p "${ROOT}/ansible/collections"
ansible-galaxy role install -r "${ROOT}/ansible/requirements.yml" -p "${ROOT}/ansible/roles"

# Run from the ansible/ directory so ansible.cfg resolves the inventory
# (./inventory for group_vars + ../build/hosts.yml for the Tofu-generated hosts).
cd "${ROOT}/ansible"

EXTRA="${ROOT}/envs/${ENV}/ansible.extra.yml"
if [ -f "${EXTRA}" ]; then
  EXTRA_FLAG=(-e @"${EXTRA}")
else
  EXTRA_FLAG=()
fi

ansible all -m ping

# The shared filesystem is provisioned by OpenTofu (managed NFS) and mounted via
# cloud-init before this runs, so Ansible only configures Slurm.
ansible-playbook playbooks/slurmdbd.yml "${EXTRA_FLAG[@]}"
ansible-playbook playbooks/slurm.yml "${EXTRA_FLAG[@]}"
