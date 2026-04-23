#!/usr/bin/env bash
set -euo pipefail

# Tail CloudWatch logs for the Lambda deployed by this repo (Bref web function).
#
# Usage:
#   ./scripts/tail_log.sh
#   STAGE=dev FOLLOW=0 ./scripts/tail_log.sh   # last hour, no follow
#
# Env:
#   STAGE       default: prod
#   REGION      default: us-west-2
#   AWS_PROFILE optional
#   SINCE       passed to aws logs tail (default: 30m). Set FOLLOW=0 for one-shot.
#   FOLLOW      default: 1 (follow). Set to 0 to dump recent logs and exit.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

STAGE="${STAGE:-prod}"
REGION="${REGION:-us-west-2}"
SERVICE_SLUG="${SERVICE_SLUG:-uu-networking-test-server}"
FN="${FN:-${SERVICE_SLUG}-${STAGE}-web}"
LOG_GROUP="${LOG_GROUP:-/aws/lambda/${FN}}"
SINCE="${SINCE:-30m}"
FOLLOW="${FOLLOW:-1}"

if ! command -v aws >/dev/null 2>&1; then
	echo "ERROR: aws CLI not found."
	exit 2
fi

echo "Tailing CloudWatch Logs"
echo "  Log group: ${LOG_GROUP}"
echo "  Region:    ${REGION}"
[[ -n "${AWS_PROFILE:-}" ]] && echo "  Profile:   ${AWS_PROFILE}"
echo "  Since:     ${SINCE}"
echo ""

args=(logs tail "${LOG_GROUP}" --region "${REGION}" "--since=${SINCE}")
if [[ "${FOLLOW}" == "1" ]]; then
	args+=(--follow)
fi

exec aws "${args[@]}"
