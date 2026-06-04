#!/usr/bin/env bash
set -euo pipefail

# Run from the ansible/ directory so testinfra's ansible backend uses
# ansible/ansible.cfg to resolve `ansible://<group>` against the
# Tofu-generated inventory (../build/hosts.yml) and group_vars.
cd "$(dirname "$0")/../ansible"

# SLURM-focused deliverable. All checks run from the controller (head node):
# slurmdbd is up, and slurmctld/sinfo/scontrol/srun plus a node-health
# threshold (SLURM_MIN_HEALTHY_PCT in tests/test_slurm.py) validate the fleet.
pytest -q \
  tests/test_slurmdbd.py \
  tests/test_slurm.py
