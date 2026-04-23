#!/usr/bin/env bash
set -euo pipefail

# Deploy PHP app (php/) to AWS Lambda via Bref + Serverless Framework.
#
# Prereqs: AWS CLI, PHP + Composer, Node.js + npx
#
# Usage:
#   ./scripts/deploy_lambda.sh
#
# Optional:
#   STAGE=dev REGION=us-west-2 AWS_PROFILE=myprofile ./scripts/deploy_lambda.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

STAGE="${STAGE:-prod}"
REGION="${REGION:-us-west-2}"

for cmd in aws php composer npx; do
	if ! command -v "${cmd}" >/dev/null 2>&1; then
		echo "ERROR: ${cmd} not found."
		exit 2
	fi
done

echo "Deploying UUNetworkingTestServer (Bref) ..."
echo "  Stage:  ${STAGE}"
echo "  Region: ${REGION}"
[[ -n "${AWS_PROFILE:-}" ]] && echo "  Profile: ${AWS_PROFILE}"

echo ""
echo "Installing PHP dependencies (vendor/)..."
composer install --no-dev --prefer-dist --no-interaction

echo ""
echo "Deploying with Serverless Framework..."
npx --yes serverless@3 deploy --stage "${STAGE}" --region "${REGION}"

echo ""
echo "Deployment info:"
npx --yes serverless@3 info --verbose --stage "${STAGE}" --region "${REGION}"
