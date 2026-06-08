#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ACTION="${1:-install}"
REMOVE_HOSTS=""

usage() {
  cat <<'EOF'
Usage: configure.sh [install|uninstall|scale] [options]

  install              Deploy Slurm (default). Same as configure.sh with no args.
  uninstall            Full purge of Slurm, munge, and MariaDB on all nodes.
  scale [--remove h1,h2]
                       Reconcile cluster to current inventory (scale up).
                       With --remove: drain the listed hosts first, then this
                       purges Slurm on them, cleans their /etc/hosts entries
                       cluster-wide, and prints steps to remove them from
                       inventory and re-run scale.

Options:
  --remove HOSTS       Comma-separated hostnames to remove (scale only).

Examples:
  ./scripts/configure.sh
  ./scripts/configure.sh install
  ./scripts/configure.sh uninstall
  ./scripts/configure.sh scale
  ./scripts/configure.sh scale --remove slurm-dev-compute-02
EOF
}

deps() {
  ansible-galaxy collection install -r "${ROOT}/ansible/requirements.yml" -p "${ROOT}/ansible/collections"
  ansible-galaxy role install -r "${ROOT}/ansible/requirements.yml" -p "${ROOT}/ansible/roles"
  cd "${ROOT}/ansible"
}

reconfigure_controller() {
  ansible slurmservers -m command -a "scontrol reconfigure" -b
}

run_install() {
  deps
  ansible all -m ping
  ansible-playbook playbooks/slurmdbd.yml
  ansible-playbook playbooks/slurm.yml
  reconfigure_controller
}

run_uninstall() {
  echo "This will fully purge Slurm, munge, and MariaDB on all inventory hosts."
  read -r -p "Type 'yes' to continue: " answer
  if [[ "${answer}" != "yes" ]]; then
    echo "Aborted."
    exit 1
  fi
  deps
  ansible-playbook playbooks/uninstall.yml
}

run_scale() {
  shift || true
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --remove)
        REMOVE_HOSTS="${2:-}"
        if [[ -z "${REMOVE_HOSTS}" ]]; then
          echo "error: --remove requires a comma-separated host list" >&2
          exit 1
        fi
        shift 2
        ;;
      *)
        echo "error: unknown scale option: $1" >&2
        usage >&2
        exit 1
        ;;
    esac
  done

  deps

  if [[ -n "${REMOVE_HOSTS}" ]]; then
    local limit="${REMOVE_HOSTS//,/,}"
    echo "Purging Slurm on: ${limit}"
    ansible-playbook playbooks/uninstall.yml --limit "${limit}" -e purge_db=false
    # Clean stale /etc/hosts entries for the removed nodes everywhere, while they
    # are still in the inventory. The --limit purge above only edits the removed
    # nodes themselves, leaving stale entries on the controller and the nodes
    # that remain in the cluster.
    echo "Cleaning /etc/hosts entries for removed nodes across the cluster"
    ansible-playbook playbooks/clean_hosts.yml -e "remove_hosts=${REMOVE_HOSTS}"
    echo ""
    echo "Remove these hosts from slurmexechosts in your inventory:"
    echo "  ${REMOVE_HOSTS//,/, }"
    echo ""
    echo "After updating inventory, reconcile the cluster:"
    echo "  ./scripts/configure.sh scale"
    exit 0
  fi

  ansible all -m ping
  ansible-playbook playbooks/slurmdbd.yml
  ansible-playbook playbooks/slurm.yml
  reconfigure_controller
}

case "${ACTION}" in
  install)
    run_install
    ;;
  uninstall)
    run_uninstall "$@"
    ;;
  scale)
    run_scale "$@"
    ;;
  -h|--help|help)
    usage
    ;;
  *)
    echo "error: unknown action '${ACTION}'" >&2
    usage >&2
    exit 1
    ;;
esac
