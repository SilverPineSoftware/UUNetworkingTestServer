#!/usr/bin/env bash
# Create a private S3 bucket for static files (well-known, zips, etc.).
#
# Before running: set a globally unique bucket name and region below (or export BUCKET / REGION).
#
# Why the us-east-1 branch? S3 CreateBucket: us-east-1 must not use LocationConstraint;
# other regions require LocationConstraint.

set -euo pipefail

BUCKET="${BUCKET:-uu-networking-test-server-static}"
REGION="${REGION:-us-west-2}"

if [[ "$BUCKET" == *YOURNAME* ]]; then
	echo "ERROR: Edit BUCKET in this script (or export BUCKET=...) to a globally unique name."
	exit 2
fi

if aws s3api head-bucket --bucket "$BUCKET" 2>/dev/null; then
	echo "Bucket already exists: s3://${BUCKET}"
	exit 0
fi

if [ "$REGION" = "us-east-1" ]; then
	aws s3api create-bucket --bucket "$BUCKET" --region "$REGION"
else
	aws s3api create-bucket --bucket "$BUCKET" --region "$REGION" \
		--create-bucket-configuration LocationConstraint="$REGION"
fi

aws s3api put-public-access-block --bucket "$BUCKET" \
	--public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

aws s3api put-bucket-encryption --bucket "$BUCKET" \
	--server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

echo "Created bucket: s3://${BUCKET} (region ${REGION})"
echo "Next: attach CloudFront OAC to this origin — see docs/s3-static-hosting.md"
echo "Then: ./scripts/sync_static_to_s3.sh"
