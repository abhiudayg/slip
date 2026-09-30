#!/usr/bin/env bash
# Provision Always Free Ampere VM + security list rules for Slip pass-engine.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ENV_NEON="${ROOT}/deploy/oci/.env.neon"
STATE="${ROOT}/deploy/oci/state.env"

: "${COMPARTMENT_ID:?Set COMPARTMENT_ID to your compartment OCID}"
: "${AVAILABILITY_DOMAIN:?Set AVAILABILITY_DOMAIN (oci iam availability-domain list)}"

if [[ -f "$ENV_NEON" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_NEON"
fi
: "${DATABASE_URL:?Run scripts/setup-neon.sh first (DATABASE_URL)}"

REGION="${OCI_REGION:-$(oci iam region-subscription list --query 'data[0].\"region-name\"' --raw-output 2>/dev/null || echo ap-mumbai-1)}"
DISPLAY_NAME="${DISPLAY_NAME:-slip-pass-engine}"
SHAPE="${SHAPE:-VM.Standard.A1.Flex}"
OCPUS="${OCPUS:-1}"
MEMORY_GB="${MEMORY_GB:-6}"
SSH_PUBKEY_FILE="${SSH_PUBKEY_FILE:-$HOME/.ssh/id_ed25519.pub}"
[[ -f "$SSH_PUBKEY_FILE" ]] || SSH_PUBKEY_FILE="$HOME/.ssh/id_rsa.pub"
[[ -f "$SSH_PUBKEY_FILE" ]] || { echo "No SSH public key found"; exit 1; }

echo "==> Region $REGION compartment $COMPARTMENT_ID"

# VCN
VCN_ID=$(oci network vcn list -c "$COMPARTMENT_ID" --display-name "$DISPLAY_NAME-vcn" \
  --query 'data[0].id' --raw-output 2>/dev/null || true)
if [[ -z "$VCN_ID" || "$VCN_ID" == "null" ]]; then
  VCN_ID=$(oci network vcn create -c "$COMPARTMENT_ID" --display-name "$DISPLAY_NAME-vcn" \
    --cidr-block "10.0.0.0/16" --dns-label slipvcn --wait-for-state AVAILABLE \
    --query 'data.id' --raw-output)
fi
echo "VCN $VCN_ID"

IGW_ID=$(oci network internet-gateway list -c "$COMPARTMENT_ID" --vcn-id "$VCN_ID" \
  --query 'data[0].id' --raw-output 2>/dev/null || true)
if [[ -z "$IGW_ID" || "$IGW_ID" == "null" ]]; then
  IGW_ID=$(oci network internet-gateway create -c "$COMPARTMENT_ID" --vcn-id "$VCN_ID" \
    --display-name "$DISPLAY_NAME-igw" --is-enabled true --query 'data.id' --raw-output)
fi

RT_ID=$(oci network route-table list -c "$COMPARTMENT_ID" --vcn-id "$VCN_ID" \
  --query 'data[0].id' --raw-output)
oci network route-table update --rt-id "$RT_ID" --force \
  --route-rules "[{\"cidrBlock\":\"0.0.0.0/0\",\"networkEntityId\":\"$IGW_ID\"}]" \
  >/dev/null

SL_ID=$(oci network security-list list -c "$COMPARTMENT_ID" --vcn-id "$VCN_ID" \
  --query 'data[0].id' --raw-output)
# Ingress SSH + 8080 (merge carefully — replace with known free-tier friendly rules)
oci network security-list update --security-list-id "$SL_ID" --force \
  --ingress-security-rules '[
    {"source":"0.0.0.0/0","protocol":"6","tcpOptions":{"destinationPortRange":{"min":22,"max":22}},"isStateless":false},
    {"source":"0.0.0.0/0","protocol":"6","tcpOptions":{"destinationPortRange":{"min":8080,"max":8080}},"isStateless":false}
  ]' \
  --egress-security-rules '[{"destination":"0.0.0.0/0","protocol":"all","isStateless":false}]' \
  >/dev/null

SUBNET_ID=$(oci network subnet list -c "$COMPARTMENT_ID" --vcn-id "$VCN_ID" \
  --display-name "$DISPLAY_NAME-subnet" --query 'data[0].id' --raw-output 2>/dev/null || true)
if [[ -z "$SUBNET_ID" || "$SUBNET_ID" == "null" ]]; then
  SUBNET_ID=$(oci network subnet create -c "$COMPARTMENT_ID" --vcn-id "$VCN_ID" \
    --display-name "$DISPLAY_NAME-subnet" --cidr-block "10.0.1.0/24" \
    --route-table-id "$RT_ID" --security-list-ids "[\"$SL_ID\"]" \
    --dns-label slipsub --wait-for-state AVAILABLE --query 'data.id' --raw-output)
fi

# Ubuntu 22.04 aarch64 image
IMAGE_ID=$(oci compute image list -c "$COMPARTMENT_ID" --operating-system "Canonical Ubuntu" \
  --operating-system-version "22.04" --shape "$SHAPE" \
  --query 'data[0].id' --raw-output)

# cloud-init
CLOUD_INIT=$(mktemp)
# Escape DATABASE_URL for embedding
DB_ESC=$(printf '%s' "$DATABASE_URL" | sed "s/'/'\\\\''/g")
cat > "$CLOUD_INIT" <<CLOUD
#cloud-config
package_update: true
packages: [openjdk-21-jre-headless, curl, unzip]
runcmd:
  - mkdir -p /opt/slip/{bin,templates,stations,certs}
  - id slip || useradd -r -s /usr/sbin/nologin slip
  - chown -R slip:slip /opt/slip
write_files:
  - path: /etc/systemd/system/slip-pass-engine.service
    content: |
      [Unit]
      Description=Slip Pass Engine
      After=network.target
      [Service]
      User=slip
      WorkingDirectory=/opt/slip
      Environment=SPRING_PROFILES_ACTIVE=neon
      Environment=FLYWAY_ENABLED=true
      Environment=JPA_DDL_AUTO=validate
      Environment=DATABASE_DRIVER=org.postgresql.Driver
      Environment=DATABASE_URL=${DB_ESC}
      Environment=SLIP_TEMPLATES_DIR=/opt/slip/templates
      Environment=SLIP_STATIONS_DIR=/opt/slip/stations
      Environment=PASS_ENGINE_DEV_MODE=false
      Environment=SERVER_PORT=8080
      ExecStart=/usr/bin/java -jar /opt/slip/bin/pass-engine.jar
      Restart=always
      RestartSec=5
      [Install]
      WantedBy=multi-user.target
  - path: /opt/slip/README
    content: |
      Deploy jar via deploy/oci/deploy-app.sh
CLOUD

INSTANCE_ID=$(oci compute instance list -c "$COMPARTMENT_ID" --display-name "$DISPLAY_NAME" \
  --lifecycle-state RUNNING --query 'data[0].id' --raw-output 2>/dev/null || true)

if [[ -z "$INSTANCE_ID" || "$INSTANCE_ID" == "null" ]]; then
  INSTANCE_ID=$(oci compute instance launch \
    --compartment-id "$COMPARTMENT_ID" \
    --availability-domain "$AVAILABILITY_DOMAIN" \
    --display-name "$DISPLAY_NAME" \
    --shape "$SHAPE" \
    --shape-config "{\"ocpus\":$OCPUS,\"memoryInGBs\":$MEMORY_GB}" \
    --image-id "$IMAGE_ID" \
    --subnet-id "$SUBNET_ID" \
    --assign-public-ip true \
    --ssh-authorized-keys-file "$SSH_PUBKEY_FILE" \
    --user-data-file "$CLOUD_INIT" \
    --wait-for-state RUNNING \
    --query 'data.id' --raw-output)
fi

PUBLIC_IP=$(oci compute instance list-vnics --instance-id "$INSTANCE_ID" \
  --query 'data[0]."public-ip"' --raw-output)

umask 077
cat > "$STATE" <<STATE
INSTANCE_ID=$INSTANCE_ID
PUBLIC_IP=$PUBLIC_IP
COMPARTMENT_ID=$COMPARTMENT_ID
VCN_ID=$VCN_ID
SUBNET_ID=$SUBNET_ID
DISPLAY_NAME=$DISPLAY_NAME
STATE

rm -f "$CLOUD_INIT"
echo "Instance $INSTANCE_ID @ $PUBLIC_IP"
echo "Wrote $STATE"
echo "Next: deploy/oci/deploy-app.sh"
