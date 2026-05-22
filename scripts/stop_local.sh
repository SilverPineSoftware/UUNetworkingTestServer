#!/usr/bin/env bash
set -euo pipefail

# Stop the local UU networking test PHP server started by deploy_local.sh.
#
# Usage:
#   ./scripts/stop_local.sh
#
# Optional (must match deploy_local.sh):
#   HOST=127.0.0.1 PORT=8080 ./scripts/stop_local.sh

HOST="${HOST:-127.0.0.1}"
PORT="${PORT:-8080}"

# Match: php -S 127.0.0.1:8080 -t php php/index.php
MATCH="php -S ${HOST}:${PORT} -t php php/index.php"

pids=()
while IFS= read -r pid; do
	[[ -n "${pid}" ]] && pids+=("${pid}")
done < <(pgrep -f "${MATCH}" 2>/dev/null || true)

# Fallback: anything listening on PORT that looks like our PHP dev server
if [[ ${#pids[@]} -eq 0 ]] && command -v lsof >/dev/null 2>&1; then
	while IFS= read -r pid; do
		[[ -z "${pid}" ]] && continue
		if ps -p "${pid}" -o command= 2>/dev/null | grep -q "php -S.*${PORT}"; then
			pids+=("${pid}")
		fi
	done < <(lsof -ti ":${PORT}" 2>/dev/null || true)
fi

if [[ ${#pids[@]} -eq 0 ]]; then
	echo "No local UU test server found on ${HOST}:${PORT}."
	exit 0
fi

echo "Stopping local UU test server (${HOST}:${PORT}) ..."
for pid in "${pids[@]}"; do
	echo "  kill ${pid}"
	kill "${pid}" 2>/dev/null || true
done

# Wait briefly, then force-kill if still running
sleep 0.5
for pid in "${pids[@]}"; do
	if kill -0 "${pid}" 2>/dev/null; then
		echo "  kill -9 ${pid}"
		kill -9 "${pid}" 2>/dev/null || true
	fi
done

echo "Done."
