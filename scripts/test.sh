#!/usr/bin/env bash
set -euo pipefail

# Run from the ansible/ directory so testinfra's ansible backend uses
# ansible/ansible.cfg to resolve `ansible://<group>` against the
# Tofu-generated inventory (../build/hosts.yml) and group_vars.
cd "$(dirname "$0")/../ansible"

# Curated subset that matches the Slurm-focused deliverable plus the managed
# shared filesystem. (Docker is no longer part of the default deliverable, so
# tests/test_docker.py is intentionally excluded here.)
pytest -q \
  tests/test_shared_fs.py \
  tests/test_slurmdbd.py \
  tests/test_slurm.py \
  tests/test_slurm_nodes.py
