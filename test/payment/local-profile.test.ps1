$ErrorActionPreference = 'Stop'
$projectFolder = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$configureScript = Join-Path $projectFolder 'tools\configure-sepay.ps1'
$testFolder = Join-Path $projectFolder ('build\payment-profile-tests\' + [Guid]::NewGuid().ToString('N'))
$configPath = Join-Path $testFolder 'sepay.clixml'
$checks = 0
function Check($condition, $label) {
    if (!$condition) { throw "FAIL: $label" }
    $script:checks++
}
function Must-Reject([scriptblock]$action, $label) {
    $rejected = $false
    try { & $action | Out-Null } catch { $rejected = $true }
    Check $rejected $label
}
$fakeSecret = 'test-only-local-payment-profile-secret-0001'
$secureSecret = ConvertTo-SecureString $fakeSecret -AsPlainText -Force
& $configureScript -AccountNumber '0000000000' -VaAccount 'VATEST001' -AccountName 'Synthetic test' -WebhookSecret $secureSecret -ConfigPath $configPath | Out-Null
$settings = Import-Clixml -LiteralPath $configPath
Check ($settings.Enabled -eq $false) 'Saving credentials must not enable checkout'
Check ($settings.WebhookSecret -is [Security.SecureString]) 'Secret round-trips as SecureString'
Check (!(Get-Content -LiteralPath $configPath -Raw).Contains($fakeSecret)) 'Plaintext secret must not appear in persisted XML'
$pointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($settings.WebhookSecret)
try {
    Check ([Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer) -ceq $fakeSecret) 'Current Windows user can decrypt the original secret'
} finally { [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer) }
Must-Reject { & $configureScript -Action Enable -ConfigPath $configPath } 'Enabling requires confirmation that the remote webhook is saved'
Check ((Import-Clixml -LiteralPath $configPath).Enabled -eq $false) 'Rejected enable must leave payments disabled'
& $configureScript -Action Enable -WebhookConfirmed -ConfigPath $configPath | Out-Null
Check ((Import-Clixml -LiteralPath $configPath).Enabled -eq $true) 'Explicit confirmation enables the saved profile'
$originalHash = (Get-FileHash -LiteralPath $configPath).Hash
$shortSecret = ConvertTo-SecureString 'short-test-key' -AsPlainText -Force
Must-Reject { & $configureScript -AccountNumber '0000000000' -VaAccount '' -AccountName 'Synthetic test' -WebhookSecret $shortSecret -ConfigPath $configPath } 'Short secret is rejected'
Must-Reject { & $configureScript -AccountNumber 'bad account' -VaAccount '' -AccountName 'Synthetic test' -WebhookSecret $secureSecret -ConfigPath $configPath } 'Malformed bank account is rejected'
$paddedSecret = ConvertTo-SecureString (' ' + $fakeSecret) -AsPlainText -Force
Must-Reject { & $configureScript -AccountNumber '0000000000' -VaAccount '' -AccountName 'Synthetic test' -WebhookSecret $paddedSecret -ConfigPath $configPath } 'Whitespace that would invalidate HMAC is rejected'
Check ((Get-FileHash -LiteralPath $configPath).Hash -eq $originalHash) 'Invalid replacement must preserve the existing profile'
& $configureScript -Action Disable -ConfigPath $configPath | Out-Null
Check ((Import-Clixml -LiteralPath $configPath).Enabled -eq $false) 'Profile can be disabled without deleting credentials'
Write-Output "PASS $checks local payment profile checks; no real credentials or bank payments used"
