# Start n8n for the inquiry-triage demo.
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
# Usage:  .\start-n8n.ps1
# Stop:   Ctrl+C in this window.

$ErrorActionPreference = 'Stop'
$projectDir = $PSScriptRoot

# --- Security: keep n8n on this machine only -------------------------
# n8n's editor has NO login. Its default listen address is 0.0.0.0,
# meaning any device on the Wi-Fi could open it. These two pin it to
# localhost. Do not remove them to "make it work from my phone" -
# that needs a deliberate firewall + auth decision, not deleting these.
$env:N8N_LISTEN_ADDRESS = '127.0.0.1'
$env:N8N_HOST            = '127.0.0.1'

# --- Security: limit which folders workflows may read/write ----------
# Pass a literal, UNEXPANDED '~'. n8n expands it internally to a native
# Windows path; a pre-expanded Git Bash path (/c/Users/...) silently
# fails to match even though the error message looks correct.
$env:N8N_RESTRICT_FILE_ACCESS_TO = '~/.n8n-files;~/lead-qualifier-data;~/inquiry-triage-data;~/lead-qualifier-crm-data'

# --- Allow the Code nodes the built-ins they actually require --------
$env:NODE_FUNCTION_ALLOW_BUILTIN = 'fs,path,os'

# --- Airtable target IDs, read from .env (gitignored) ----------------
# These are identifiers, not secrets. The Airtable TOKEN lives in n8n's
# own credential store and must never appear in this file.
$envFile = Join-Path $projectDir '.env'
if (-not (Test-Path $envFile)) {
    Write-Host "ERROR: no .env found at $envFile" -ForegroundColor Red
    Write-Host "Copy .env.example to .env and fill in AIRTABLE_BASE_ID"
    Write-Host "and AIRTABLE_INQUIRIES_TABLE_ID. Without them the"
    Write-Host "workflow runs almost to the end, then dies on the final"
    Write-Host "Airtable write."
    exit 1
}

Remove-Item env:AIRTABLE_BASE_ID -ErrorAction SilentlyContinue
Remove-Item env:AIRTABLE_INQUIRIES_TABLE_ID -ErrorAction SilentlyContinue

Get-Content $envFile | ForEach-Object {
    $line = $_.Trim()
    if ($line -and -not $line.StartsWith('#') -and $line.Contains('=')) {
        $name, $value = $line.Split('=', 2)
        Set-Item -Path "env:$($name.Trim())" -Value $value.Trim()
    }
}

$exampleFile = Join-Path $projectDir '.env.example'
$exampleValues = @{}
if (Test-Path $exampleFile) {
    Get-Content $exampleFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith('#') -and $line.Contains('=')) {
            $name, $value = $line.Split('=', 2)
            $exampleValues[$name.Trim()] = $value.Trim()
        }
    }
}

foreach ($required in 'AIRTABLE_BASE_ID', 'AIRTABLE_INQUIRIES_TABLE_ID') {
    $actual = (Get-Item "env:$required" -ErrorAction SilentlyContinue).Value
    if (-not $actual) {
        Write-Host "ERROR: $required is not set in .env" -ForegroundColor Red
        exit 1
    }
    if ($exampleValues.ContainsKey($required) -and $exampleValues[$required] -and $actual -eq $exampleValues[$required]) {
        Write-Host "ERROR: $required in .env is still the .env.example placeholder value." -ForegroundColor Red
        Write-Host "Replace it with your own Airtable base/table ID before starting."
        exit 1
    }
}

# n8n 2.30+ blocks $env access inside nodes by default. The two
# Airtable nodes read the IDs above via $env, so this must be off.
$env:N8N_BLOCK_ENV_ACCESS_IN_NODE = 'false'

Write-Host ""
Write-Host "All seven settings applied. Starting n8n..." -ForegroundColor Green
Write-Host "Editor will be at http://127.0.0.1:5678 (this machine only)."
Write-Host ""

npx n8n
