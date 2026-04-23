#!/usr/bin/env bash
set -euo pipefail

# Upload (sync) static-public/ → S3. Re-run after local changes; uses --delete (S3 mirrors local).
# Skips hidden / junk files (.DS_Store, .gitkeep, etc.). The directory ".well-known/" still syncs;
# only dot-prefixed file names are excluded (see SYNC_EXCLUDES).
#
# Important: aws s3 sync --exclude does NOT delete matching keys already in S3 — excluded files are
# ignored for both upload and removal. After sync we run a second pass (Python) to delete junk keys.
# Zips get application/zip; .json under .well-known get application/json; .html text/html.
#
# Usage:
#   BUCKET=my-bucket ./scripts/sync_static_to_s3.sh
# Or edit BUCKET below.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOCAL_DIR="${REPO_ROOT}/static-public"

BUCKET="${BUCKET:-uu-networking-test-server-static}"
REGION="${REGION:-us-west-2}"

if [[ "$BUCKET" == *YOURNAME* ]]; then
	echo "ERROR: Set BUCKET (export BUCKET=... or edit this script)."
	exit 2
fi

if [[ ! -d "${LOCAL_DIR}" ]]; then
	echo "ERROR: Missing directory: ${LOCAL_DIR}"
	exit 2
fi

if ! command -v aws >/dev/null 2>&1; then
	echo "ERROR: aws CLI not found."
	exit 2
fi

DEST="s3://${BUCKET}/"

# Dotfiles / OS junk — do not upload. (Paths like ".well-known/assetlinks.json" are kept: basename has no leading dot.)
SYNC_EXCLUDES=(
	--exclude "**/.DS_Store"
	--exclude "**/.Spotlight-V100/**"
	--exclude "**/.Trashes/**"
	--exclude "**/.TemporaryItems/**"
	--exclude "**/.AppleDouble/**"
	--exclude "**/.git/**"
	--exclude "**/.gitignore"
	--exclude "**/.gitattributes"
	--exclude "**/.gitkeep"
	--exclude "**/.hg/**"
	--exclude "**/.svn/**"
	--exclude "**/.idea/**"
	--exclude "**/.vscode/**"
	--exclude "**/._*"
)

echo "Syncing ${LOCAL_DIR}/ → ${DEST} (region ${REGION})"
aws s3 sync "${LOCAL_DIR}/" "${DEST}" --delete --region "${REGION}" "${SYNC_EXCLUDES[@]}"

echo "Removing junk keys already in S3 (.DS_Store, etc.; sync --exclude does not remove them)"
python3 - "${BUCKET}" "${REGION}" << 'PY'
import json, subprocess, sys

bucket, region = sys.argv[1], sys.argv[2]


def aws_json(cmd):
    out = subprocess.check_output(["aws"] + cmd, text=True)
    return json.loads(out)


def junk_key(key: str) -> bool:
    base = key.rsplit("/", 1)[-1]
    if base in {".DS_Store", ".gitkeep", ".gitignore", ".gitattributes"}:
        return True
    if base.startswith("._") and len(base) >= 3:
        return True
    for part in (
        "/.Spotlight-V100/",
        "/.Trashes/",
        "/.TemporaryItems/",
        "/.AppleDouble/",
        "/.git/",
        "/.hg/",
        "/.svn/",
        "/.idea/",
        "/.vscode/",
    ):
        if part in key:
            return True
    return False


keys = []
token = ""
while True:
    cmd = [
        "s3api",
        "list-objects-v2",
        "--bucket",
        bucket,
        "--region",
        region,
        "--output",
        "json",
    ]
    if token:
        cmd.extend(["--continuation-token", token])
    data = aws_json(cmd)
    for obj in data.get("Contents") or []:
        k = obj["Key"]
        if junk_key(k):
            keys.append(k)
    token = data.get("NextContinuationToken") or ""
    if not token:
        break

for i in range(0, len(keys), 1000):
    batch = keys[i : i + 1000]
    payload = {"Objects": [{"Key": k} for k in batch], "Quiet": True}
    subprocess.check_call(
        [
            "aws",
            "s3api",
            "delete-objects",
            "--bucket",
            bucket,
            "--region",
            region,
            "--delete",
            json.dumps(payload),
        ]
    )
    print(f"Deleted {len(batch)} junk object(s)", file=sys.stderr)

if not keys:
    print("No junk keys to remove.", file=sys.stderr)
PY

# Fix Content-Type for common types (sync may leave octet-stream on some objects).
fix_file() {
	local rel="$1"
	local type="$2"
	local cache="${3:-max-age=3600}"
	local src="${LOCAL_DIR}/${rel}"
	if [[ -f "${src}" ]]; then
		aws s3 cp "${src}" "${DEST}${rel}" \
			--region "${REGION}" \
			--content-type "${type}" \
			--cache-control "${cache}"
	fi
}

if [[ -f "${LOCAL_DIR}/.well-known/apple-app-site-association" ]]; then
	fix_file ".well-known/apple-app-site-association" "application/json" "max-age=300"
fi
if [[ -f "${LOCAL_DIR}/.well-known/assetlinks.json" ]]; then
	fix_file ".well-known/assetlinks.json" "application/json" "max-age=300"
fi

while IFS= read -r -d '' z; do
	rel="${z#"${LOCAL_DIR}/"}"
	fix_file "${rel}" "application/zip" "max-age=86400"
done < <(find "${LOCAL_DIR}" -type f -name '*.zip' -print0)

while IFS= read -r -d '' h; do
	rel="${h#"${LOCAL_DIR}/"}"
	fix_file "${rel}" "text/html; charset=utf-8" "max-age=3600"
done < <(find "${LOCAL_DIR}" -type f \( -name '*.html' -o -name '*.htm' \) -print0)

echo "Done."
