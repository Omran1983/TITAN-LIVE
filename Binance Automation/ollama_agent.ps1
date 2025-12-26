param(
  [string]$Model = "llama3.1",
  [string]$Task  = "Set up Streamlit UI and run it.",
  [string]$ProjectRoot = "."
)

$ErrorActionPreference = "Stop"
$ProjectRoot = (Resolve-Path $ProjectRoot).Path
Set-Location $ProjectRoot

function Invoke-OllamaChat {
  param([string]$Model,[array]$Messages,[array]$Tools)
  $body = @{ model=$Model; stream=$false; messages=$Messages; tools=$Tools } | ConvertTo-Json -Depth 10
  Invoke-RestMethod -Uri "http://localhost:11434/api/chat" -Method POST -ContentType "application/json" -Body $body
}

$tools = @(
  @{ type="function"; function=@{ name="write_file"; description="Write a UTF-8 file in project dir."; parameters=@{ type="object"; properties=@{ path=@{type="string"}; content=@{type="string"} }; required=@("path","content") } } },
  @{ type="function"; function=@{ name="append_file"; description="Append UTF-8 text to a file."; parameters=@{ type="object"; properties=@{ path=@{type="string"}; content=@{type="string"} }; required=@("path","content") } } },
  @{ type="function"; function=@{ name="run_powershell"; description="Run one safe PowerShell command in project dir."; parameters=@{ type="object"; properties=@{ command=@{type="string"} }; required=@("command") } } }
)

function Invoke-SafePS {
  param([string]$Cmd)
  if ($Cmd -match "(?i)(Remove-Item| rmdir | rd | del | format | reg | sc | schtasks | bcdedit | diskpart | Enable-PSRemoting)") {
    throw "Blocked dangerous command: $Cmd"
  }
  Invoke-Expression $Cmd | Out-String
}

function Parse-ToolArgs {
  param([string]$Name, [string]$ArgStr)
  try { return $ArgStr | ConvertFrom-Json -ErrorAction Stop } catch {}
  $raw = ($ArgStr -replace '^\s+','' -replace '\s+$','')
  if ($Name -eq "run_powershell") {
    if ($raw -match "(?is)run_powershell\s*:\s*['`"](.+?)['`"]\s*$") { return @{ command=$matches[1] } }
    return @{ command=$raw }
  }
  if ($Name -in @("write_file","append_file")) {
    $path=$null; $content=$null
    if ($raw -match "(?mi)^\s*path\s*:\s*['`"]?(.+?)['`"]?\s*$")    { $path=$matches[1] }
    if ($raw -match "(?smi)^\s*content\s*:\s*(['`"]?)(.+)\1\s*$")  { $content=$matches[2] }
    if ($path -and $content) { return @{ path=$path; content=$content } }
    throw ("Could not parse arguments for {0}. Provide JSON or keys path: and content:." -f $Name)
  }
  throw ("Unsupported arg format for {0}." -f $Name)
}

$sys = "You are a build & ops agent for $ProjectRoot. Use ONE tool call per step (write_file, append_file, run_powershell). Stay inside project root. No destructive commands. Be incremental."

$messages = @(@{role="system"; content=$sys}, @{role="user"; content=$Task})

while ($true) {
  $resp = Invoke-OllamaChat -Model $Model -Messages $messages -Tools $tools
  if (-not $resp -or -not $resp.message) { Write-Warning "No message from model."; break }
  $assistant = $resp.message

  if (-not $assistant.tool_calls -or $assistant.tool_calls.Count -eq 0) {
    Write-Host "`n=== Agent Output ===`n$($assistant.content)"
    break
  }

  $call   = $assistant.tool_calls[0]
  $name   = $call.function.name
  $argStr = [string]$call.function.arguments
  Write-Host ("`n[tool-call] {0}" -f $name)
  #Write-Host ("args: {0}" -f $argStr)

  try { $args = Parse-ToolArgs -Name $name -ArgStr $argStr } catch {
    $toolResult = "ERROR parsing args: $($_.Exception.Message)"
    Write-Host "[tool-result] $toolResult"
    $messages += @{role="assistant"; tool_calls=$assistant.tool_calls; content=$assistant.content}
    $messages += @{role="tool"; name=$name; content=$toolResult}
    continue
  }

  try {
    switch ($name) {
      "write_file" {
        $target = Join-Path $ProjectRoot $args.path
        New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
        Set-Content -Encoding UTF8 -Path $target -Value $args.content
        $toolResult = "Wrote: $($args.path) (len=$([string]$args.content).Length)"
      }
      "append_file" {
        $target = Join-Path $ProjectRoot $args.path
        if (-not (Test-Path $target)) { throw "File not found: $($args.path)" }
        Add-Content -Path $target -Value $args.content
        $toolResult = "Appended: $($args.path) (len+=$([string]$args.content).Length)"
      }
      "run_powershell" {
        $toolResult = Invoke-SafePS $args.command
      }
      default { $toolResult = "Unknown tool: $name" }
    }
  } catch { $toolResult = "ERROR: $($_.Exception.Message)" }

  Write-Host "[tool-result] $toolResult"
  $messages += @{role="assistant"; tool_calls=$assistant.tool_calls; content=$assistant.content}
  $messages += @{role="tool"; name=$name; content=$toolResult}
}
