<#
Tests the Alea AGMS Stats API and exports the 10 latest rows to Excel.

  Settings come from a .env file in the repo root (copy .env.example) or
  environment variables: ALEA_GROUP_ID plus one auth method -
  ALEA_AUTHORIZATION (header value), ALEA_COOKIE (session cookie) or
  ALEA_USER / ALEA_PASS (LoginUserName / LoginPassword).

  Usage (PowerShell):
    .\Get-AleaLatest.ps1                     # today
    .\Get-AleaLatest.ps1 -Days 7 -Top 10     # last 7 days up to today

Writes alea_latest.xlsx (via Excel) next to this script, or alea_latest.csv
if Excel is not installed. Credentials are read from environment variables so
they never end up in the file or in git.
#>
param(
  [int]$Days = 0,                                          # 0 = today only
  [int]$Top = 10,
  [string]$Url = "https://lb.aleacontrol.com/AGMS/api/Stats",
  # Defaults copied from Trevor's sample request (12 Oct 2026).
  [int[]]$GroupBy = @(4),                                  # 4 = Location
  [string[]]$Groups = @(),                                 # default: $env:ALEA_GROUP_ID
  [object]$Games = $null                                   # $null = all games
)
$ErrorActionPreference = "Stop"

# Load .env from the repo root (same format as Codex's Import-DotEnv.ps1).
$envFile = Join-Path (Split-Path (Split-Path $PSScriptRoot -Parent) -Parent) ".env"
if (Test-Path $envFile) {
  foreach ($line in Get-Content $envFile) {
    $t = $line.Trim()
    if (-not $t -or $t.StartsWith("#") -or $t -notmatch "=") { continue }
    $k, $v = $t -split "=", 2
    [Environment]::SetEnvironmentVariable($k.Trim(), $v.Trim().Trim('"').Trim("'"), "Process")
  }
}
if (-not $Groups) { $Groups = @($env:ALEA_GROUP_ID) }
if (-not $Groups[0]) { throw "ALEA_GROUP_ID is required (.env or environment)." }
if (-not ($env:ALEA_AUTHORIZATION -or $env:ALEA_COOKIE -or ($env:ALEA_USER -and $env:ALEA_PASS))) {
  Write-Warning "No ALEA_AUTHORIZATION, ALEA_COOKIE or ALEA_USER/ALEA_PASS set - expect ResponseCode 2."
}
$headers = @{ Accept = "application/json" }
if ($env:ALEA_AUTHORIZATION) { $headers.Authorization = $env:ALEA_AUTHORIZATION }
elseif ($env:ALEA_USER) {
  # Password grant on /token -> Bearer token (verified endpoint, 13 Oct 2026).
  $tokenUrl = ($Url -replace '/api/Stats$', '') + '/token'
  try {
    $t = Invoke-RestMethod -Uri $tokenUrl -Method Post -ContentType 'application/x-www-form-urlencoded' `
           -Body @{ grant_type = 'password'; userName = $env:ALEA_USER; password = $env:ALEA_PASS }
  } catch { throw "Alea login failed at $tokenUrl : $($_.Exception.Message)" }
  $headers.Authorization = "Bearer $($t.access_token)"
  Write-Host "Logged in to Alea (token expires in $($t.expires_in)s)."
}
if ($env:ALEA_COOKIE) { $headers.Cookie = $env:ALEA_COOKIE }

# Trevor's sample uses StartDate 07 / EndDate 08 for one day, so the end
# date is treated as exclusive: today = today .. tomorrow.
$start = (Get-Date).Date.AddDays(-$Days)
$end   = (Get-Date).Date.AddDays(1)
$body = [ordered]@{
  Date           = @{ StartDate = $start.ToString("yyyy-MM-dd"); EndDate = $end.ToString("yyyy-MM-dd") }
  groupBy        = $GroupBy
  groups         = $Groups
  locations      = $null
  statisticBy    = $null
  games          = $Games
  CCY            = $null
  paymentSources = $null
}
$json = $body | ConvertTo-Json -Depth 6

Write-Host "Calling $Url for $($body.Date.StartDate) .. $($body.Date.EndDate)"
try {
  $resp = Invoke-RestMethod -Uri $Url -Method Post -ContentType "application/json" -Body $json -Headers $headers
} catch {
  $code = $_.Exception.Response.StatusCode.value__
  throw "Connection FAILED (HTTP $code): $($_.Exception.Message)"
}

# Alea wraps results as { ResponseCode, Message, <data> }; report the status.
if ($null -ne $resp.ResponseCode) {
  Write-Host "ResponseCode: $($resp.ResponseCode)  Message: '$($resp.Message)'"
  if ($resp.ResponseCode -eq 2) {
    throw "Reachable but NOT authenticated (ResponseCode 2). Get Alea's supported API auth (token/header, API key or approved session cookie) - see README."
  }
}

# Find the first array in the response - that is the row data.
function Find-Rows($node) {
  if ($node -is [System.Array]) { return ,$node }
  if ($node -is [psobject]) {
    foreach ($p in $node.PSObject.Properties) {
      $r = Find-Rows $p.Value
      if ($r) { return ,$r }
    }
  }
  return $null
}
$rows = Find-Rows $resp
if (-not $rows -or $rows.Count -eq 0) {
  Write-Warning "Connected, but no rows came back. Raw response saved to alea_raw.json."
  $resp | ConvertTo-Json -Depth 10 | Set-Content "$PSScriptRoot\alea_raw.json"
  exit 1
}

# Flatten nested objects so every value gets its own Excel column.
function Flatten($obj, $prefix = "") {
  $out = [ordered]@{}
  foreach ($p in $obj.PSObject.Properties) {
    $name = if ($prefix) { "$prefix.$($p.Name)" } else { $p.Name }
    if ($p.Value -is [psobject] -and -not ($p.Value -is [string])) {
      (Flatten $p.Value $name).GetEnumerator() | ForEach-Object { $out[$_.Key] = $_.Value }
    } elseif ($p.Value -is [System.Array]) {
      $out[$name] = ($p.Value -join "; ")
    } else { $out[$name] = $p.Value }
  }
  [pscustomobject]$out
}
$flat = $rows | ForEach-Object { Flatten $_ }

# "Latest" = sort by the first date-like column if there is one, newest first.
$dateCol = $flat[0].PSObject.Properties.Name | Where-Object { $_ -match 'date|time' } | Select-Object -First 1
$latest = if ($dateCol) { $flat | Sort-Object { [datetime]$_.$dateCol } -Descending | Select-Object -First $Top }
          else          { $flat | Select-Object -Last $Top }

Write-Host "Connection OK - $($rows.Count) rows returned, exporting $(@($latest).Count)." -ForegroundColor Green

$csv = "$PSScriptRoot\alea_latest.csv"
$latest | Export-Csv $csv -NoTypeInformation -Encoding UTF8
try {
  $xl = New-Object -ComObject Excel.Application
  $xl.DisplayAlerts = $false
  $wb = $xl.Workbooks.Open($csv)
  $xlsx = "$PSScriptRoot\alea_latest.xlsx"
  $wb.SaveAs($xlsx, 51)   # 51 = .xlsx
  $wb.Close(); $xl.Quit()
  Write-Host "Saved $xlsx"
} catch {
  Write-Host "Excel not available - saved $csv (opens in Excel)."
}
$latest | Format-Table -AutoSize
