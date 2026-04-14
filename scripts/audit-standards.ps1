param(
  [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

Write-Host "Running standards audit in: $Root"

$brokenLinks = @()
$markdownFiles = Get-ChildItem -Path $Root -Recurse -File -Filter *.md

foreach ($file in $markdownFiles) {
  $content = Get-Content -LiteralPath $file.FullName
  $matches = $content | Select-String -Pattern '\[[^\]]+\]\(([^)]+)\)' -AllMatches

  foreach ($line in $matches) {
    foreach ($match in $line.Matches) {
      $target = $match.Groups[1].Value

      if ($target -match '^(https?://|mailto:|#)') {
        continue
      }

      $resolved = Join-Path $file.DirectoryName $target
      if (-not (Test-Path -LiteralPath $resolved)) {
        $brokenLinks += [pscustomobject]@{
          File = $file.FullName
          Target = $target
        }
      }
    }
  }
}

$suspiciousDirs = @(Get-ChildItem -Path $Root -Recurse -Directory |
  Where-Object { $_.Name -match '^\{.+\}$' } |
  Select-Object -ExpandProperty FullName)

if ($brokenLinks.Count -gt 0) {
  Write-Host "`nBroken markdown links found:" -ForegroundColor Red
  $brokenLinks | Format-Table -AutoSize
} else {
  Write-Host "`nNo broken markdown links found." -ForegroundColor Green
}

if ($suspiciousDirs.Count -gt 0) {
  Write-Host "`nSuspicious directories found (likely accidental):" -ForegroundColor Yellow
  $suspiciousDirs | ForEach-Object { Write-Host " - $_" }
} else {
  Write-Host "`nNo suspicious brace-named directories found." -ForegroundColor Green
}

if ($brokenLinks.Count -gt 0 -or $suspiciousDirs.Count -gt 0) {
  Write-Host "`nAudit failed." -ForegroundColor Red
  exit 1
}

Write-Host "`nAudit passed." -ForegroundColor Green
