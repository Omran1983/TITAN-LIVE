function Get-AOGRLMailCredential {
    param(
        [string]$Path = "F:\AION-ZERO\secrets\deals-smtp.xml"
    )

    if (-not (Test-Path $Path)) {
        throw "SMTP credential file not found at $Path. Run the credential setup first."
    }

    Import-Clixml $Path
}

function Send-AOGRLMail {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$To,
        [Parameter(Mandatory)] [string]$Subject,
        [Parameter(Mandatory)] [string]$Body,
        [string]$From = "deals@aogrl.com",
        [switch]$IsHtml
    )

    $smtpHost = "smtp.office365.com"
    $smtpPort = 587
    $cred     = Get-AOGRLMailCredential

    $msg = New-Object System.Net.Mail.MailMessage($From, $To, $Subject, $Body)

    if ($IsHtml) {
        $msg.IsBodyHtml = $true
    }

    $smtp = New-Object System.Net.Mail.SmtpClient($smtpHost, $smtpPort)
    $smtp.EnableSsl   = $true
    $smtp.Credentials = $cred

    $smtp.Send($msg)
}
