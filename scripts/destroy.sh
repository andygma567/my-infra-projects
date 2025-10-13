#!/usr/bin/env bash
set -euo pipefail
ENV="${1:-dev}"
cd "$(dirname "$0")/../tofu"
tofu destroy -auto-approve -var-file="../envs/${ENV}/tofu.tfvars"
