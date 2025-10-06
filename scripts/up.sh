#!/usr/bin/env bash
set -euo pipefail
ENV="${1:-dev}"
cd "$(dirname "$0")/../tofu"
tofu init -input=false
tofu apply -auto-approve -var-file="../envs/${ENV}/tofu.tfvars"
