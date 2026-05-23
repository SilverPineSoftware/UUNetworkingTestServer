#!/usr/bin/env bash
set -euo pipefail

# List objects in the static bucket (recursive).

BUCKET="${BUCKET:-uu-networking-test-server-static-YOURNAME}"
REGION="${REGION:-us-west-2}"

if [[ "$BUCKET" == *YOURNAME* ]]; then
	echo "ERROR: Set BUCKET (export BUCKET=... or edit this script)."
	exit 2
fi

if ! command -v aws >/dev/null 2>&1; then
	echo "ERROR: aws CLI not found."
	exit 2
fi

aws s3 ls "s3://${BUCKET}/" --recursive --region "${REGION}"
