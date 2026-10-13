<#
Tests the Alea AGMS Stats API and exports the 10 latest rows to Excel.

  Usage (PowerShell):
    $env:ALEA_USER = "your LoginUserName"
    $env:ALEA_PASS = "your LoginPassword"
    .\Get-AleaLatest.ps1                     # last 7 days
    .\Get-AleaLatest.ps1 -Days 1 -Top 10

Writes alea_latest.xlsx (via Excel) next to this script, or alea_latest.csv
if Excel is not installed. Credentials are read from environment variables so
they never end up in the file or in git.
#>
param(
  [int]$Days = 7,
  [int]$Top = 10,
  [string]$Url = "https://lb.aleacontrol.com/AGMS/api/Stats",
  # Defaults copied from Trevor's sample request (12 Oct 2026).
  [int[]]$GroupBy = @(4),                                  # 4 = Location
  [string[]]$Groups = @("{609f0dd2-1ad2-453a-b57e-f6ac8283d30a}"),
  [object]$Games = $null                                   # $null = all games
)
$ErrorActionPreference = "Stop"

if (-not $env:ALEA_USER -or -not $env:ALEA_PASS) {
  throw "Set `$env:ALEA_USER and `$env:ALEA_PASS first (your Alea LoginUserName / LoginPassword)."
}

$end   = Get-Date
$start = $end.AddDays(-$Days)
$body = [ordered]@{
  LoginUserName  = $env:ALEA_USER
  LoginPassword  = $env:ALEA_PASS
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
  $resp = Invoke-RestMethod -Uri $Url -Method Post -ContentType "application/json" -Body $json `
            -Headers @{ LoginUserName = $env:ALEA_USER; LoginPassword = $env:ALEA_PASS }
} catch {
  $code = $_.Exception.Response.StatusCode.value__
  throw "Connection FAILED (HTTP $code): $($_.Exception.Message)"
}

# Alea wraps results as { ResponseCode, Message, <data> }; report the status.
if ($null -ne $resp.ResponseCode) {
  Write-Host "ResponseCode: $($resp.ResponseCode)  Message: '$($resp.Message)'"
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
