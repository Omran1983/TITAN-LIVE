<#
    Jarvis-Voice.ps1
    ----------------
    The "Mouth" of AION-ZERO.
    Uses Windows Native Text-to-Speech (Zero Cost).
#>

param(
    [Parameter(Mandatory = $true)][string]$Text,
    [int]$Rate = 1 # Speed (-10 to 10)
)

Add-Type -AssemblyName System.Speech

$synthesizer = New-Object System.Speech.Synthesis.SpeechSynthesizer
$synthesizer.Rate = $Rate

# Check for "Zira" (Standard US English Female) or "David" (Male)
# You can list installed voices with: $synthesizer.GetInstalledVoices().VoiceInfo.Name
try {
    $synthesizer.SelectVoiceByHints([System.Speech.Synthesis.VoiceGender]::Female)
}
catch {
    # Fallback to default
}

Write-Host "[VOICE] Speaking: '$Text'" -ForegroundColor Cyan
$synthesizer.Speak($Text)
