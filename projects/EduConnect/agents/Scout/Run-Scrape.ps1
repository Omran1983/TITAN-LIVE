param()
$stamp = Get-Date -Format "yyyyMMdd_HHmm"
$csv = "F:\EduConnect\data\seed_scrape_$stamp.csv"
$src = "https://httpbin.org/uuid"
try {
  $r = Invoke-RestMethod -Uri $src -Method GET -TimeoutSec 20
  [pscustomobject]@{ ts=(Get-Date).ToString("o"); source=$src; value=$r.uuid } |
    Export-Csv -NoTypeInformation -Path $csv
  Write-Host "Scrape done -> $csv"
} catch {
  $err = $_.Exception.Message
  $log = "F:\EduConnect\logs\scrape_$stamp.err.log"
  "ERR,{0:o},${err}" -f (Get-Date) | Out-File -FilePath $log -Encoding UTF8
  Write-Warning "Scrape failed -> $log"
  exit 1
}
exit 0
