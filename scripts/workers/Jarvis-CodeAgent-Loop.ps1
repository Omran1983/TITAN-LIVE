# FULL AUTONOMOUS CODE AGENT LOOP (Stage 4)
$ErrorActionPreference = "Stop"
. "F:\AION-ZERO\scripts\Jarvis-LoadEnv.ps1"

Write-Host "`n=== CodeAgent v2 Running ==="

while ($true) {
    try {
        $headers = @{
            apikey        = $env:SUPABASE_SERVICE_ROLE_KEY
            Authorization = "Bearer $env:SUPABASE_SERVICE_ROLE_KEY"
        }

        $url = "$($env:SUPABASE_URL)/rest/v1/az_commands?select=*&action=eq.code&status=eq.queued&limit=1"
        $cmd = Invoke-RestMethod -Method Get -Uri $url -Headers $headers

        if ($cmd.Count -gt 0) {
            $id = $cmd[0].id
            $instruction = $cmd[0].instruction

            # In-progress
            $patch = @{status="in_progress"} | ConvertTo-Json
            Invoke-RestMethod -Method Patch -Uri "$($env:SUPABASE_URL)/rest/v1/az_commands?id=eq.$id" -Headers $headers -Body $patch

            # Target file (ReachX UI)
            $file = "F:\ReachX-AI\ui\reachx-demo-app.html"
            $content = Get-Content $file -Raw

            $marker = "<!-- JARVIS-AUTO -->"
            if ($content -notmatch $marker) {
                $content = $content.Replace("</head>", "$marker`n</head>")
            }

            $content = $content.Replace(
                $marker,
                "$marker`n<!-- CMD#$id : $instruction -->`n"
            )

            Set-Content -Path $file -Value $content -Encoding UTF8

            # Done
            $patch = @{status="done"} | ConvertTo-Json
            Invoke-RestMethod -Method Patch -Uri "$($env:SUPABASE_URL)/rest/v1/az_commands?id=eq.$id" -Headers $headers -Body $patch
        }
    } catch {
        Write-Host "[CodeAgent ERROR] $_" -ForegroundColor Red
    }

    Start-Sleep -Seconds 10
}
