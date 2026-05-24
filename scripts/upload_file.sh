#!/usr/bin/env bash
set -euo pipefail

# Upload a local file to the UU test server via form.php (multipart field uu_file).
#
# Usage:
#   ./scripts/upload_file.sh <file_path>
#
# Example:
#   ./scripts/upload_file.sh static-public/downloads/zip_100_1024.zip
#
# Optional:
#   UU_TEST_SERVER_HOST=https://uu.spsw.io ./scripts/upload_file.sh ./myfile.jpg
#   UU_TEST_SERVER_HOST=http://127.0.0.1:8080 ./scripts/upload_file.sh ./myfile.jpg

UU_TEST_SERVER_HOST="${UU_TEST_SERVER_HOST:-https://uu.spsw.io}"
UU_TEST_SERVER_HOST="${UU_TEST_SERVER_HOST%/}"

usage() {
	echo "Usage: $0 <file_path>" >&2
	echo "  POSTs the file to \${UU_TEST_SERVER_HOST}/form.php (default: https://uu.spsw.io)." >&2
	exit 1
}

[[ $# -eq 1 ]] || usage

FILE_PATH="$1"

if ! command -v curl >/dev/null 2>&1; then
	echo "ERROR: curl not found." >&2
	exit 2
fi

if [[ ! -f "${FILE_PATH}" ]]; then
	echo "ERROR: not a file: ${FILE_PATH}" >&2
	exit 1
fi

FILE_PATH="$(cd "$(dirname "${FILE_PATH}")" && pwd)/$(basename "${FILE_PATH}")"
FILE_NAME="$(basename "${FILE_PATH}")"
FORM_URL="${UU_TEST_SERVER_HOST}/form.php"

echo "Uploading ${FILE_NAME} → ${FORM_URL}"
RESPONSE="$(curl -fsS -X POST "${FORM_URL}" -F "uu_file=@${FILE_PATH};filename=${FILE_NAME}")"
echo "Server: ${RESPONSE}"

if [[ "${RESPONSE}" != *"Upload finished, result: 1"* && "${RESPONSE}" != *"Upload finished, result: true"* ]]; then
	echo "ERROR: upload did not report success." >&2
	exit 1
fi
