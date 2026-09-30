#!/usr/bin/env bash
# Interactive OCI CLI config for Always Free deploy.
set -euo pipefail

if ! command -v oci >/dev/null 2>&1; then
  echo "Install oci-cli: brew install oci-cli" >&2
  exit 1
fi

mkdir -p "$HOME/.oci"
if [[ -f "$HOME/.oci/config" ]]; then
  echo "Found ~/.oci/config"
  oci iam region list --output table | head -20 || true
else
  echo "==> Running oci setup config (needs tenancy OCID, user OCID, API key)"
  echo "Create an API key in OCI Console → Identity → Users → API Keys if needed."
  oci setup config
fi

echo "==> Verify"
oci iam compartment list --compartment-id-in-subtree true --all \
  --query "data[].{name:\"name\",id:\"id\"}" --output table | head -40

echo "Next: export COMPARTMENT_ID=... and run deploy/oci/provision.sh"
