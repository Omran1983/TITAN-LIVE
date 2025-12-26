param(
    [string]$ConfigPath = "$PSScriptRoot\Jarvis-ReflexEngine.config.json"
)

$ErrorActionPreference = "Stop"

# --- Collect telemetry (placeholder for now) ---

# CPU (simple approximation)
$cpuSample = Get-Counter '\Processor(_Total)\% Processor Time' -SampleInterval 1 -MaxSamples 1
$cpuValue  = [math]::Round($cpuSample.CounterSamples[0].CookedValue, 0)

# Placeholder telemetry - later plug in Supabase / logs
$queueDepth = 12       # TODO: compute from job table
$errorRate  = 0.08     # TODO: compute from failures / total jobs

$telemetry = @{
    queue_depth = $queueDepth
    error_rate  = $errorRate
    cpu         = $cpuValue
}

# --- Rules (you can tune these thresholds) ---

$rules = @(
    @{
        id        = 1
        name      = "High queue depth"
        trigger   = "queue_depth_high"
        enabled   = $true
        threshold = 10
    },
    @{
        id        = 2
        name      = "High error rate"
        trigger   = "error_rate_high"
        enabled   = $true
        threshold = 0.05
    },
    @{
        id        = 3
        name      = "High CPU"
        trigger   = "cpu_high"
        enabled   = $true
        threshold = 70
    }
)

$config = @{
    telemetry = $telemetry
    rules     = $rules
}

$configJson = $config | ConvertTo-Json -Depth 5
Set-Content -LiteralPath $ConfigPath -Value $configJson -Encoding UTF8

Write-Host "ReflexConfig: wrote config to $ConfigPath"
