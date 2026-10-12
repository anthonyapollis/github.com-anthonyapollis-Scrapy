# Runs the RavenTrack collection headless with Newman and writes rotated
# tokens back to the local environment file so the next run stays connected.
#   One-time:  npm install -g newman
#              Copy-Item RavenTrack.postman_environment.template.json RavenTrack.postman_environment.local.json
#              (then paste a fresh refresh_token into the .local.json file)
param(
  [string]$Env = "$PSScriptRoot\RavenTrack.postman_environment.local.json"
)
$ErrorActionPreference = "Stop"
if (-not (Test-Path $Env)) { throw "Missing $Env - copy the template and add your refresh_token." }

newman run "$PSScriptRoot\RavenTrack-Automated.postman_collection.json" `
  --environment $Env `
  --export-environment $Env `
  --reporters cli
exit $LASTEXITCODE
