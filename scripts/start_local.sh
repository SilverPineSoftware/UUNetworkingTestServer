#!/usr/bin/env bash
set -euo pipefail

# Run the UU networking test PHP server locally (built-in PHP web server).
#
# Prereq: PHP 8.x on PATH
#
# Usage:
#   ./scripts/deploy_local.sh
#
# Optional:
#   HOST=127.0.0.1 PORT=8080 ./scripts/deploy_local.sh
#   UU_FILE_FOLDER=/tmp/my-upload ./scripts/deploy_local.sh
#
# Point iOS Simulator tests at:
#   http://127.0.0.1:8080  (set test_server_api_host in UUNetworkingTestConfig.plist)
#
# Stop with Ctrl+C, or: ./scripts/stop_local.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
cd "${REPO_ROOT}"

HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8080}"
UU_FILE_FOLDER="${UU_FILE_FOLDER:-/tmp/uu-upload}"

if ! command -v php >/dev/null 2>&1; then
	echo "ERROR: php not found."
	exit 2
fi

mkdir -p "${UU_FILE_FOLDER}"
export UU_FILE_FOLDER

BASE_URL="http://${HOST}:${PORT}"

echo "Starting UUNetworkingTestServer (local PHP) ..."
echo "  URL:           ${BASE_URL}/"
echo "  Document root: ${REPO_ROOT}/php"
echo "  Upload folder: ${UU_FILE_FOLDER}"
echo ""
echo "Examples:"
echo "  ${BASE_URL}/"
echo "  ${BASE_URL}/echo_json.php"
echo "  ${BASE_URL}/echo/json"
echo "  ${BASE_URL}/form.php"
echo ""
echo "Press Ctrl+C to stop."
echo ""

exec php -S "${HOST}:${PORT}" -t php php/index.php
