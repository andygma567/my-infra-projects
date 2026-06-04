#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../tofu"
tofu init -input=false
tofu apply -auto-approve
