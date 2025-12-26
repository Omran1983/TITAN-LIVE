# F:\AION-ZERO\scripts\Invoke-EduConnectHealth.ps1

$ErrorActionPreference = "Stop"

$global:EduHealthAgent = "EduConnect-Health"

function Write-EduHealthEvent {
    param(
        [string]$Action,
        [string]$Status  = "success",
        [string]$Details = $null
    )

    & "F:\AION-ZERO\scripts\Write-ProxyEvent.ps1" `
        -Project "EduConnect" `
        -Agent   $global:EduHealthAgent `
        -Action  $Action `
        -Status  $Status `
        -Details $Details
}

try {
    . "F:\AION-ZERO\scripts\Load-Supabase.ps1"

    # -------------------------------------------------
    # 1) Cloudflare Worker health
    # -------------------------------------------------
    $workerUrl = "https://educonnect-hq-lite.dubsy1983-51e.workers.dev"

    Write-EduHealthEvent -Action "worker-health-start" -Status "running" -Details "GET $workerUrl"

    try {
        $resp = Invoke-WebRequest -Uri $workerUrl -Method Get -TimeoutSec 15 -ErrorAction Stop

        $code = $resp.StatusCode
        $snippet = $null
        if ($resp.Content) {
            $snippet = ($resp.Content.Substring(0, [Math]::Min(200, $resp.Content.Length))).Replace("`r"," ").Replace("`n"," ")
        }

        if ($code -eq 200) {
            Write-EduHealthEvent -Action "worker-health" -Status "success" -Details "HTTP $code OK; body: $snippet"
        }
        else {
            Write-EduHealthEvent -Action "worker-health" -Status "error" -Details "HTTP $code; body: $snippet"
            throw "Worker responded with HTTP $code"
        }
    }
    catch {
        $msg = $_.Exception.Message
        Write-EduHealthEvent -Action "worker-health" -Status "error" -Details "Exception: $msg"
        throw
    }

    # -------------------------------------------------
    # 2) Supabase REST heartbeat (via proxy_events)
    # -------------------------------------------------
    try {
        $hbUri = "$SBURL/rest/v1/proxy_events" +
                 "?select=id" +
                 "&order=id.desc" +
                 "&limit=1"

        $hbResp = Invoke-RestMethod -Uri $hbUri -Headers $SBHeaders -Method Get -ErrorAction Stop

        if ($hbResp) {
            Write-EduHealthEvent -Action "supabase-heartbeat" -Status "success" -Details "REST OK via proxy_events"
        }
        else {
            Write-EduHealthEvent -Action "supabase-heartbeat" -Status "error" -Details "REST returned empty result"
            throw "Supabase REST heartbeat returned empty"
        }
    }
    catch {
        $msg = $_.Exception.Message
        Write-EduHealthEvent -Action "supabase-heartbeat" -Status "error" -Details "Exception: $msg"
        throw
    }
}
catch {
    # Bubble up so AZ-CommandPoller can mark command as error
    throw
}
