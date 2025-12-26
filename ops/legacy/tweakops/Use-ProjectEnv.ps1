param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('okasina','educonnect','az','reachx')]
    [string] $Project
)

# Load global env
. 'F:\tweakops\Load-DotEnv.ps1' -EnvFilePath 'F:\secrets\.env-main'

switch ($Project) {
    'okasina' {
        # Frontend / scripts that expect SUPABASE_URL + ANON
        $env:SUPABASE_URL      = $env:EDU_SUPABASE_URL
        $env:SUPABASE_ANON_KEY = $env:EDU_SUPABASE_ANON_KEY
        Write-Host "OKASINA env set (EDU project, anon key)" -ForegroundColor Green
    }
    'educonnect' {
        # Worker / scripts that expect SBURL + SBKEY
        $env:SBURL = $env:EDU_SUPABASE_URL
        $env:SBKEY = $env:EDU_SUPABASE_SERVICE_KEY
        Write-Host "EduConnect env set (EDU project, service key)" -ForegroundColor Green
    }
    'az' {
        # AION-ZERO core — using JARVIS Supabase
        $env:SBURL = $env:JARVIS_SUPABASE_URL
        $env:SBKEY = $env:JARVIS_SUPABASE_SERVICE_KEY
        Write-Host "AION-ZERO env set (JARVIS project)" -ForegroundColor Green
    }
    'reachx' {
        # ReachX-AI — also using JARVIS Supabase
        $env:SBURL = $env:JARVIS_SUPABASE_URL
        $env:SBKEY = $env:JARVIS_SUPABASE_SERVICE_KEY
        Write-Host "ReachX env set (JARVIS project)" -ForegroundColor Green
    }
}
