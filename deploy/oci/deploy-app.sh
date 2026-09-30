#!/usr/bin/env bash
# Build pass-engine jar and rsync to Always Free VM.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STATE="${ROOT}/deploy/oci/state.env"
[[ -f "$STATE" ]] || { echo "Run provision.sh first"; exit 1; }
# shellcheck disable=SC1090
source "$STATE"
: "${PUBLIC_IP:?}"

SSH_USER="${SSH_USER:-ubuntu}"
SSH=(ssh -o StrictHostKeyChecking=accept-new "$SSH_USER@$PUBLIC_IP")

echo "==> Building jar"
(cd "$ROOT/pass-engine" && mvn -q -DskipTests package)
JAR=$(ls "$ROOT/pass-engine/target/pass-engine-"*.jar | head -1)

echo "==> Uploading to $PUBLIC_IP"
"${SSH[@]}" "sudo mkdir -p /opt/slip/{bin,templates,stations,certs} && sudo chown -R \$USER /opt/slip"
rsync -az "$JAR" "$SSH_USER@$PUBLIC_IP:/opt/slip/bin/pass-engine.jar"
rsync -az "$ROOT/templates/" "$SSH_USER@$PUBLIC_IP:/opt/slip/templates/"
rsync -az "$ROOT/stations/" "$SSH_USER@$PUBLIC_IP:/opt/slip/stations/"

"${SSH[@]}" 'sudo systemctl daemon-reload && sudo systemctl enable --now slip-pass-engine && sudo systemctl restart slip-pass-engine'
sleep 3
curl -fsS "http://$PUBLIC_IP:8080/v1/health" || true
echo
echo "API base: http://$PUBLIC_IP:8080"
echo "Set SlipAPIBaseURL / SlipAPIBaseURL in iOS Info.plist to that URL (HTTPS reverse proxy recommended)."
