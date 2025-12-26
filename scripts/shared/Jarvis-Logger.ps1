# Jarvis-Logger.ps1

param(
    [string]$Component = "core"
)

function Write-JLog {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("INFO","WARN","ERROR","DEBUG")]
        [string]$Level,
        [Parameter(Mandatory)]
        [string]$Message
    )
    # ... body ...
}

# Export-ModuleMember is only for .psm1 modules, not dot-sourced scripts.
# Commented out to avoid runtime error when dot-sourcing.
# Export-ModuleMember -Function Write-JLog

