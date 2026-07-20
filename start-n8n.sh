#!/usr/bin/env bash
# Start n8n for the inquiry-triage demo (macOS/Linux).
#
# Run this instead of typing the env vars by hand. Every one of the
# seven below is load-bearing, and the two security ones fail SILENTLY
# when missing - n8n starts fine and looks normal, it's just reachable
# from the whole network. That is exactly how they went missing once
# already (see playbooks/fixes-log.md, n8n 2.30 entry).
#
# n8n on this machine hosts all three portfolio workflows in one
# instance, so this script (like lead-qualifier-crm's) allowlists all
# three projects' data folders, not just this one - running either
# script starts the same shared n8n.
#
# Usage:  ./start-n8n.sh
# Stop:   Ctrl+C in this terminal.

set -euo pipefail
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Security: keep n8n on this machine only -------------------------
# n8n's editor has NO login. Its default listen address is 0.0.0.0,
# meaning any device on the Wi-Fi could open it. These two pin it to
# localhost. Do not remove them to "make it work from my phone" - that
# needs a deliberate firewall + auth decision, not deleting these.
export N8N_LISTEN_ADDRESS='127.0.0.1'
export N8N_HOST='127.0.0.1'

# --- Security: limit which folders workflows may read/write ----------
export N8N_RESTRICT_FILE_ACCESS_TO='~/.n8n-files;~/lead-qualifier-data;~/inquiry-triage-data;~/lead-qualifier-crm-data'

# --- Allow the Code nodes the built-ins they actually require --------
export NODE_FUNCTION_ALLOW_BUILTIN='fs,path,os'

# --- Airtable target IDs, read from .env (gitignored) -----------------
# These are identifiers, not secrets. The Airtable TOKEN lives in n8n's
# own credential store and must never appear in this file.
ENV_FILE="$PROJECT_DIR/.env"
if [ ! -f "$ENV_FILE" ]; then
    echo "ERROR: no .env found at $ENV_FILE" >&2
    echo "Copy .env.example to .env and fill in AIRTABLE_BASE_ID and" >&2
    echo "AIRTABLE_INQUIRIES_TABLE_ID. Without them the workflow runs" >&2
    echo "almost to the end, then dies on the final Airtable write." >&2
    exit 1
fi

unset AIRTABLE_BASE_ID AIRTABLE_INQUIRIES_TABLE_ID

set -a
# shellcheck disable=SC1090
source "$ENV_FILE"
set +a

EXAMPLE_FILE="$PROJECT_DIR/.env.example"

for required in AIRTABLE_BASE_ID AIRTABLE_INQUIRIES_TABLE_ID; do
    if [ -z "${!required:-}" ]; then
        echo "ERROR: $required is not set in .env" >&2
        exit 1
    fi
    if [ -f "$EXAMPLE_FILE" ]; then
        example_value="$(grep -E "^${required}=" "$EXAMPLE_FILE" | head -1 | cut -d= -f2-)"
        if [ -n "$example_value" ] && [ "${!required}" = "$example_value" ]; then
            echo "ERROR: $required in .env is still the .env.example placeholder value." >&2
            echo "Replace it with your own Airtable base/table ID before starting." >&2
            exit 1
        fi
    fi
done

# n8n 2.30+ blocks $env access inside nodes by default. The two
# Airtable nodes read the IDs above via $env, so this must be off.
export N8N_BLOCK_ENV_ACCESS_IN_NODE='false'

echo ""
echo "All seven settings applied. Starting n8n..."
echo "Editor will be at http://127.0.0.1:5678 (this machine only)."
echo ""

npx n8n
