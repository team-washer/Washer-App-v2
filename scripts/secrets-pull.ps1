#!/usr/bin/env pwsh
# Restore all secret files from Infisical into their correct paths — one command.
# Fetches each base64 secret and decodes it back to the original (text or binary) file.
#
# Usage:
#   ./scripts/secrets-pull.ps1                # pulls from the "dev" environment
#   ./scripts/secrets-pull.ps1 -Env prod      # pulls from the "prod" environment
#
# Prereqs: `infisical login` and `infisical init` must have been run in this repo.

param(
    [string]$Env = "dev"
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
. (Join-Path $PSScriptRoot "secrets-map.ps1")

foreach ($name in $SecretMap.Keys) {
    $path = Join-Path $root $SecretMap[$name]
    $b64 = (infisical secrets get $name --plain --env $Env)
    if ($LASTEXITCODE -ne 0) { throw "infisical secrets get failed for $name" }
    $b64 = ($b64 | Out-String).Trim()
    if ([string]::IsNullOrWhiteSpace($b64)) {
        Write-Warning "skip $name  (empty in Infisical)"
        continue
    }
    $dir = Split-Path -Parent $path
    if ($dir -and -not (Test-Path $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    [IO.File]::WriteAllBytes($path, [Convert]::FromBase64String($b64))
    Write-Host "pulled  $name  ->  $($SecretMap[$name])"
}

Write-Host "`nDone. Secret files restored from environment '$Env'."
