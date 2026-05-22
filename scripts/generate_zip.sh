#!/usr/bin/env bash
set -euo pipefail

# Generate N text files filled with random lorem ipsum (up to M words each) and zip them.
#
# Usage:
#   ./scripts/generate_zip.sh <file_count> <word_count>
#
# Example:
#   ./scripts/generate_zip.sh 100 1024
#   → static-public/downloads/zip_100_1024.zip
#
# Optional:
#   OUTPUT_DIR=/path/to/dir ./scripts/generate_zip.sh 10 512

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
OUTPUT_DIR="${OUTPUT_DIR:-${REPO_ROOT}/files}"

usage() {
	echo "Usage: $0 <file_count> <word_count>" >&2
	echo "  Creates zip_{file_count}_{word_count}.zip with random lorem ipsum text files." >&2
	exit 1
}

[[ $# -eq 2 ]] || usage

FILE_COUNT="$1"
WORD_COUNT="$2"

if ! [[ "${FILE_COUNT}" =~ ^[0-9]+$ ]] || ! [[ "${WORD_COUNT}" =~ ^[0-9]+$ ]]; then
	echo "ERROR: file_count and word_count must be positive integers." >&2
	exit 1
fi

if [[ "${FILE_COUNT}" -lt 1 ]] || [[ "${WORD_COUNT}" -lt 1 ]]; then
	echo "ERROR: file_count and word_count must be at least 1." >&2
	exit 1
fi

for cmd in zip python3; do
	if ! command -v "${cmd}" >/dev/null 2>&1; then
		echo "ERROR: ${cmd} not found." >&2
		exit 2
	fi
done

mkdir -p "${OUTPUT_DIR}"

ZIP_BASENAME="zip_${FILE_COUNT}_${WORD_COUNT}"
ZIP_PATH="${OUTPUT_DIR}/${ZIP_BASENAME}.zip"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/uu-zip.XXXXXX")"
cleanup() {
	rm -rf "${WORK_DIR}"
}
trap cleanup EXIT

PAD="${#FILE_COUNT}"
[[ "${PAD}" -lt 4 ]] && PAD=4

echo "Generating ${FILE_COUNT} files (up to ${WORD_COUNT} words each) ..."
python3 - "${WORK_DIR}" "${FILE_COUNT}" "${WORD_COUNT}" "${PAD}" <<'PY'
import random
import sys
from pathlib import Path

out_dir = Path(sys.argv[1])
file_count = int(sys.argv[2])
word_count = int(sys.argv[3])
pad = int(sys.argv[4])

lorem = """
lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod tempor
incididunt ut labore et dolore magna aliqua ut enim ad minim veniam quis
nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat
duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore
eu fugiat nulla pariatur excepteur sint occaecat cupidatat non proident sunt
in culpa qui officia deserunt mollit anim id est laborum
""".split()

for i in range(1, file_count + 1):
    n = random.randint(1, word_count)
    text = " ".join(random.choice(lorem) for _ in range(n))
    path = out_dir / f"file_{i:0{pad}d}.txt"
    path.write_text(text + "\n", encoding="utf-8")
PY

echo "Zipping → ${ZIP_PATH}"
rm -f "${ZIP_PATH}"
(
	cd "${WORK_DIR}"
	zip -q -r "${ZIP_PATH}" .
)

echo "Done: ${ZIP_PATH} ($(du -h "${ZIP_PATH}" | awk '{print $1}'))"
