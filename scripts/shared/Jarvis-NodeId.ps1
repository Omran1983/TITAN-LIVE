# Jarvis-NodeId.ps1
# Determines which logical node this process represents.

param(
    [string]$DefaultNodeCode = "NODE-HQ"
)

function Get-JarvisNodeCode {
    param(
        [string]$Override
    )
    if ($Override) { return $Override }

    # 1) ENV override
    if ($env:JARVIS_NODE_CODE) { return $env:JARVIS_NODE_CODE }

    # 2) Machine-based fallback (hostname)
    $hostname = $env:COMPUTERNAME
    if ($hostname) {
        return "NODE-$hostname"
    }

    # 3) Hard fallback
    return $DefaultNodeCode
}

# Export-ModuleMember is only valid inside a .psm1 module; this file is dot-sourced.
# Export-ModuleMember -Function Get-JarvisNodeId