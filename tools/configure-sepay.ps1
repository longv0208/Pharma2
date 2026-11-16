param(
    [ValidateSet('Configure', 'Status', 'Enable', 'Disable')][string]$Action = 'Configure',
    [string]$AccountNumber,
    [string]$VaAccount,
    [string]$AccountName,
    [string]$BankCode = 'MB',
    [string]$Gateway = 'MBBank',
    [Security.SecureString]$WebhookSecret,
    [switch]$WebhookConfirmed,
    [string]$ConfigPath = (Join-Path $env:LOCALAPPDATA 'PharmaFlow\payments\sepay.clixml')
)
$ErrorActionPreference = 'Stop'
$settings = $null
if (Test-Path -LiteralPath $ConfigPath) { $settings = Import-Clixml -LiteralPath $ConfigPath }
if ($Action -eq 'Configure') {
    if (!$AccountNumber) { $AccountNumber = Read-Host 'Main bank account (not the VA)' }
    if (!$PSBoundParameters.ContainsKey('VaAccount')) { $VaAccount = Read-Host 'Official VA (leave empty if not used)' }
    if (!$PSBoundParameters.ContainsKey('AccountName')) { $AccountName = Read-Host 'Account holder name' }
    $AccountNumber = $AccountNumber.Trim()
    $VaAccount = "$VaAccount".Trim()
    if ($AccountNumber -notmatch '^[A-Za-z0-9]{1,19}$' -or
            ($VaAccount -and $VaAccount -notmatch '^[A-Za-z0-9]{1,19}$')) {
        throw 'Invalid main bank account or VA. Nothing was saved.'
    }
    if (!$WebhookSecret) { $WebhookSecret = Read-Host 'SePay webhook HMAC secret (hidden input)' -AsSecureString }
    if ($WebhookSecret.Length -lt 32) { throw 'HMAC secret must contain at least 32 characters. Nothing was saved.' }
    $secretPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($WebhookSecret)
    try {
        $plainSecret = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($secretPointer)
        if ($plainSecret -cne $plainSecret.Trim() -or $plainSecret -match '[\x00\r\n]') {
            throw 'Paste the exact HMAC key without surrounding whitespace or line breaks. Nothing was saved.'
        }
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($secretPointer)
        $plainSecret = $null
    }
    if ($BankCode -notmatch '^[A-Za-z0-9]{1,20}$' -or $Gateway -notmatch '^[A-Za-z0-9]{1,40}$') {
        throw 'Invalid bank code or gateway. Nothing was saved.'
    }
    $settings = [pscustomobject]@{
        Enabled = $false
        AccountNumber = $AccountNumber
        VaAccount = $VaAccount
        AccountName = "$AccountName".Trim()
        BankCode = $BankCode
        Gateway = $Gateway
        WebhookSecret = $WebhookSecret
    }
}
if (!$settings) {
    if ($Action -eq 'Status') { Write-Output 'SePay local profile: not configured'; return }
    throw 'Configure the local profile first.'
}
if ($Action -eq 'Enable') {
    if (!$WebhookConfirmed) { throw 'Confirm that the matching SePay webhook is saved before enabling: -WebhookConfirmed' }
    if ($settings.WebhookSecret -isnot [Security.SecureString] -or $settings.WebhookSecret.Length -lt 32 -or
            $settings.AccountNumber -notmatch '^[A-Za-z0-9]{1,19}$' -or
            ($settings.VaAccount -and $settings.VaAccount -notmatch '^[A-Za-z0-9]{1,19}$') -or
            $settings.BankCode -notmatch '^[A-Za-z0-9]{1,20}$' -or $settings.Gateway -notmatch '^[A-Za-z0-9]{1,40}$') {
        throw 'Invalid profile. Configure the local profile again.'
    }
    $settings.Enabled = $true
}
if ($Action -eq 'Disable') { $settings.Enabled = $false }
if ($Action -ne 'Status') {
    $folder = Split-Path -Parent ([IO.Path]::GetFullPath($ConfigPath))
    New-Item -ItemType Directory -Path $folder -Force | Out-Null
    # Export-Clixml encrypts SecureString with Windows DPAPI for this user/machine.
    $settings | Export-Clixml -LiteralPath $ConfigPath -Encoding UTF8
}
[pscustomobject]@{
    ConfigPath = [IO.Path]::GetFullPath($ConfigPath)
    Enabled = [bool]$settings.Enabled
    BankCode = $settings.BankCode
    VirtualAccountSelected = [bool]$settings.VaAccount
    SecretStored = $settings.WebhookSecret -is [Security.SecureString]
} | Format-List
if ($Action -eq 'Configure') {
    Write-Output 'Saved with payments disabled. Save the matching webhook on SePay, then use -Action Enable -WebhookConfirmed and restart the PharmaFlow preview.'
}
