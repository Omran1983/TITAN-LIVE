param(
    [string]$Environment       = "dev",
    [int]$PollIntervalSeconds  = 60
)

Write-Host "=== Jarvis Design Agent (Ollama) starting (env=$Environment) ===" -ForegroundColor Cyan

if (-not $env:SUPABASE_URL -or -not $env:SUPABASE_SERVICE_ROLE_KEY) {
    Write-Error "SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY not set."
    exit 1
}

$baseUrl   = $env:SUPABASE_URL.Trim() -replace "/+$",""
$apiKey    = $env:SUPABASE_SERVICE_ROLE_KEY
$designUrl = $baseUrl + "/rest/v1/jarvis_design_tasks"

$headers = @{
    "apikey"        = $apiKey
    "Authorization" = "Bearer $apiKey"
    "Content-Type"  = "application/json"
}

function Invoke-DesignLLM {
    param(
        [string]$SpecText,
        [string]$ModelName = "phi3:mini"
    )

    $ollamaModel = if ($env:OLLAMA_MODEL) { $env:OLLAMA_MODEL } else { $ModelName }
    $uri         = "http://localhost:11434/api/chat"

    $sysPrompt = @"
You are Jarvis-DesignAgent, an elite systems architect and code generator.
- Output ONLY the requested code or content, no explanations.
- Use best-practice patterns, clear structure, and comments when appropriate.
- Assume this runs in Omran's automation ecosystem (Jarvis + ReachX + AION-ZERO) on Windows.
"@

    $bodyObj = @{
        model    = $ollamaModel
        messages = @(
            @{
                role    = "system"
                content = $sysPrompt
            },
            @{
                role    = "user"
                content = $SpecText
            }
        )
        stream = $false
    }

    $bodyJson = $bodyObj | ConvertTo-Json -Depth 6

    try {
        $resp = Invoke-RestMethod -Method Post -Uri $uri -Body $bodyJson -ContentType "application/json" -ErrorAction Stop

        if ($resp -and $resp.message -and $resp.message.content) {
            return $resp.message.content
        } elseif ($resp.choices -and $resp.choices.Count -gt 0 -and $resp.choices[0].message.content) {
            return $resp.choices[0].message.content
        } else {
            throw "Ollama returned no content."
        }
    } catch {
        throw "Invoke-DesignLLM (Ollama) error: $($_.ToString())"
    }
}

function Get-NextDesignTask {
    param(
        [string]$Env
    )

    $uri = $designUrl + "?environment=eq." + $Env + "&status=eq.queued&order=created_at.asc&limit=1"
    Write-Host "DEBUG design task URI: [$uri]" -ForegroundColor DarkGray

    try {
        $tasks = Invoke-RestMethod -Method Get -Uri $uri -Headers $headers -ErrorAction Stop
        if ($tasks -and $tasks.Count -gt 0) { return $tasks[0] }
        return $null
    } catch {
        Write-Error "Error polling jarvis_design_tasks: $_"
        return $null
    }
}

function Update-DesignTaskStatus {
    param(
        [long]$TaskId,
        [string]$Status,
        [string]$LastError = $null,
        [string]$OutputPreview = $null,
        [bool]$SetStarted  = $false,
        [bool]$SetFinished = $false
    )

    $patch = @{}
    $patch["status"] = $Status

    $nowIso = (Get-Date).ToString("o")
    if ($SetStarted)  { $patch["started_at"]  = $nowIso }
    if ($SetFinished) { $patch["finished_at"] = $nowIso }

    if ($LastError)     { $patch["last_error"]          = $LastError }
    if ($OutputPreview) { $patch["last_output_preview"] = $OutputPreview }

    $body = $patch | ConvertTo-Json -Depth 5
    $uri  = $designUrl + "?id=eq." + $TaskId

    Write-Host "DEBUG update design task ${TaskId}: [$uri]" -ForegroundColor DarkGray
    Write-Host "DEBUG patch: $body" -ForegroundColor DarkGray

    $localHeaders = $headers.Clone()
    $localHeaders["Prefer"] = "return=representation"

    try {
        $resp = Invoke-RestMethod -Method Patch -Uri $uri -Headers $localHeaders -Body $body -ErrorAction Stop
        return $resp
    } catch {
        Write-Error "Failed to update jarvis_design_tasks ${TaskId}: $_"
    }
}

function Handle-DesignTask {
    param(
        $taskRow
    )

    $taskId      = $taskRow.id
    $specText    = $taskRow.spec_text
    $outputPath  = $taskRow.output_path
    $outputFmt   = if ($taskRow.output_format) { $taskRow.output_format } else { "raw" }
    $modelName   = if ($taskRow.model -and $taskRow.model.Trim()) { $taskRow.model.Trim() } else { "phi3:mini" }

    Write-Host "Handling design task id=$taskId, output=$outputPath, format=$outputFmt" -ForegroundColor Yellow

    Update-DesignTaskStatus -TaskId $taskId -Status "running" -SetStarted $true | Out-Null

    $errMsg   = $null
    $content  = $null

    try {
        $content = Invoke-DesignLLM -SpecText $specText -ModelName $modelName

        if (-not $content) {
            throw "Design result is empty."
        }

        if ($outputPath) {
            $directory = Split-Path $outputPath -Parent
            if ($directory -and -not (Test-Path $directory)) {
                New-Item -ItemType Directory -Path $directory -Force | Out-Null
            }

            switch ($outputFmt) {
                "ps1" {
                    $content = $content -replace "`r?`n","`r`n"
                }
                default {
                    # leave as-is
                }
            }

            Set-Content -Path $outputPath -Value $content -Encoding UTF8
            Write-Host "Design output written to $outputPath" -ForegroundColor Green
        } else {
            Write-Host "No output_path set; design result kept only in Supabase preview." -ForegroundColor Yellow
        }

        $preview = if ($content.Length -gt 400) { $content.Substring(0, 400) } else { $content }

        Update-DesignTaskStatus -TaskId $taskId -Status "done" -OutputPreview $preview -SetFinished $true | Out-Null
    }
    catch {
        $errMsg = $_.ToString()
        Write-Host "Design task $taskId failed: $errMsg" -ForegroundColor Red
        Update-DesignTaskStatus -TaskId $taskId -Status "failed" -LastError $errMsg -SetFinished $true | Out-Null
    }
}

while ($true) {
    Write-Host "[$(Get-Date -Format 'u')] Jarvis-DesignAgent (Ollama) polling for design tasks..." -ForegroundColor DarkGray
    $task = Get-NextDesignTask -Env $Environment

    if ($task) {
        Handle-DesignTask -taskRow $task
    } else {
        Start-Sleep -Seconds $PollIntervalSeconds
    }
}
