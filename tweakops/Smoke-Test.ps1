param([string]$Proj="F:\AION-ZERO")
$hero = Join-Path $Proj "src\components\Hero.jsx"
$css  = Join-Path $Proj "src\styles\buttons.css"
$bakH = "$hero.bak"; $bakC = "$css.bak"
Copy-Item $hero $bakH -Force; Copy-Item $css $bakC -Force
try {
  pwsh -NoProfile -File "$Proj\tweakops\Submit-Tweak.ps1" `
    -Client okasina `
    -Intent "Change CTA text to 'Shop Now – 23% OFF' and darken hover" `
    -TargetFiles "src\components\Hero.jsx,src\styles\buttons.css"
  Start-Sleep 2
  $h = Get-Content -Raw $hero
  $c = Get-Content -Raw $css
  if ($h -notmatch 'Shop Now\s*[–-]\s*23%\s*OFF' -or $c -notmatch '\.btn-primary:hover') { throw "SMOKE_FAIL" }
  "SMOKE_OK"
} catch {
  Copy-Item $bakH $hero -Force; Copy-Item $bakC $css -Force
  "SMOKE_FAIL"
} finally {
  Remove-Item $bakH,$bakC -Force -ErrorAction SilentlyContinue
}
