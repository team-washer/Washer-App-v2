#!/usr/bin/env pwsh
# Seed local secret files into Infisical (run once, or whenever a file changes).
# Each file is base64-encoded and stored as a single Infisical secret.
#
# Usage:
#   ./scripts/secrets-push.ps1                # uploads to the "dev" environment
#   ./scripts/secrets-push.ps1 -Env prod      # uploads to the "prod" environment
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
    if (-not (Test-Path $path)) {
        Write-Warning "skip $name  (not found: $($SecretMap[$name]))"
        continue
    }
    $b64 = [Convert]::ToBase64String([IO.File]::ReadAllBytes($path))
    infisical secrets set "$name=$b64" --env $Env | Out-Null
    if ($LASTEXITCODE -ne 0) { throw "infisical secrets set failed for $name" }
    Write-Host "pushed  $name  <-  $($SecretMap[$name])"
}

Write-Host "`nDone. Secrets uploaded to environment '$Env'."
