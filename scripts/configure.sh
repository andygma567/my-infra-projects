#!/usr/bin/env bash
set -euo pipefail
ENV="${1:-dev}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
INV="${ROOT}/build/inventory.ini"

ansible-galaxy collection install -r "${ROOT}/ansible/requirements.yml" -p "${ROOT}/ansible/collections"

ansible -i "${INV}" all -m ping
EXTRA="${ROOT}/envs/${ENV}/ansible.extra.yml"
if [ -f "${EXTRA}" ]; then
  EXTRA_FLAG=(-e @"${EXTRA}")
else
  EXTRA_FLAG=()
fi

ansible-playbook -i "${INV}" "${ROOT}/ansible/playbooks/nfs.yml" "${EXTRA_FLAG[@]}"
ansible-playbook -i "${INV}" "${ROOT}/ansible/playbooks/docker.yml" "${EXTRA_FLAG[@]}"
ansible-playbook -i "${INV}" "${ROOT}/ansible/playbooks/slurmdbd.yml" "${EXTRA_FLAG[@]}"
ansible-playbook -i "${INV}" "${ROOT}/ansible/playbooks/slurm.yml" "${EXTRA_FLAG[@]}"
