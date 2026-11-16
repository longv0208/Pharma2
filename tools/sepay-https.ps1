param(
    [ValidateSet('Start', 'Status', 'Stop', 'RestartGateway')][string]$Action = 'Status',
    [ValidateRange(1024, 65535)][int]$GatewayPort = 18181,
    [ValidateRange(1024, 65535)][int]$TomcatPort = 18080,
    [ValidateRange(15, 180)][int]$ConnectTimeoutSeconds = 60,
    [ValidateSet('auto', 'http2', 'quic')][string]$TunnelProtocol = 'auto',
    [string]$NodePath = 'C:\Program Files\nodejs\node.exe',
    [string]$CloudflaredPath = 'C:\Program Files (x86)\cloudflared\cloudflared.exe'
)
$ErrorActionPreference = 'Stop'
$gatewayScript = Join-Path $PSScriptRoot 'sepay-webhook-gateway.cjs'
$runtimeFolder = Join-Path $env:LOCALAPPDATA 'PharmaFlow\sepay-webhook'
$stateFile = Join-Path $runtimeFolder 'state.json'
$saved = if (Test-Path -LiteralPath $stateFile) { Get-Content -LiteralPath $stateFile -Raw | ConvertFrom-Json } else { $null }

function Get-OwnedProcess($processId, $executable, $marker) {
    if (!$processId -or !$marker) { return $null }
    $candidate = Get-CimInstance Win32_Process -Filter "ProcessId = $([int]$processId)" -ErrorAction SilentlyContinue
    if ($candidate -and $candidate.ExecutablePath -eq $executable -and
            $candidate.CommandLine.IndexOf($marker, [StringComparison]::OrdinalIgnoreCase) -ge 0) {
        return $candidate
    }
    return $null
}

function Stop-OwnedRuntime($state) {
    if (!$state) { return }
    $tunnelProcess = Get-OwnedProcess $state.tunnelPid $state.cloudflaredPath $state.tunnelLog
    $gatewayProcess = Get-OwnedProcess $state.gatewayPid $state.nodePath $state.gatewayScript
    if ($tunnelProcess) { Stop-Process -Id $tunnelProcess.ProcessId -ErrorAction Stop }
    if ($gatewayProcess) { Stop-Process -Id $gatewayProcess.ProcessId -ErrorAction Stop }
}

function Test-PublicHealth($healthUrl) {
    if (!$healthUrl) { return $false }
    try {
        $health = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 4
        $script:lastPublicHealthError = if ($health.service -eq 'PharmaFlow-SePay-webhook') { $null } else { 'Unexpected health response.' }
        return $health.service -eq 'PharmaFlow-SePay-webhook'
    } catch {
        $script:lastPublicHealthError = $_.Exception.Message
        return $false
    }
}

function Test-QuickTunnelDns($healthUrl) {
    try {
        $hostname = ([Uri]$healthUrl).DnsSafeHost
        $query = 'https://cloudflare-dns.com/dns-query?name=' + [Uri]::EscapeDataString($hostname) + '&type=A'
        $answer = Invoke-RestMethod -Uri $query -Headers @{ Accept = 'application/dns-json' } -TimeoutSec 4
        if ($answer.Status -eq 3) { return $false }
        return @($answer.Answer | Where-Object { $_.type -eq 1 }).Count -gt 0
    } catch {
        # If DoH is unavailable, still try the normal system resolver.
        return $null
    }
}

function Show-Status($state) {
    if (!$state) { Write-Output 'No PharmaFlow webhook tunnel has been started.'; return }
    $gatewayProcess = Get-OwnedProcess $state.gatewayPid $state.nodePath $state.gatewayScript
    $tunnelProcess = Get-OwnedProcess $state.tunnelPid $state.cloudflaredPath $state.tunnelLog
    $reachable = if ($gatewayProcess -and $tunnelProcess) { Test-PublicHealth $state.healthUrl } else { $false }
    [pscustomobject]@{
        GatewayRunning = [bool]$gatewayProcess
        TunnelRunning = [bool]$tunnelProcess
        PublicHttpsReachable = $reachable
        WebhookUrl = if ($reachable) { $state.webhookUrl } else { $null }
        HealthUrl = if ($reachable) { $state.healthUrl } else { $null }
        StartedAt = $state.startedAt
        RuntimeFolder = $runtimeFolder
    } | Format-List
}

if ($Action -eq 'Status') { Show-Status $saved; return }
if ($Action -eq 'RestartGateway') {
    if (!$saved -or $saved.gatewayScript -ne $gatewayScript -or
            !(Get-OwnedProcess $saved.tunnelPid $saved.cloudflaredPath $saved.tunnelLog)) {
        throw 'No owned live tunnel was found. Use Start instead.'
    }
    $gatewayProcess = Get-OwnedProcess $saved.gatewayPid $saved.nodePath $saved.gatewayScript
    $listener = Get-NetTCPConnection -State Listen -LocalPort $saved.gatewayPort -ErrorAction SilentlyContinue
    if ($listener -and (!$gatewayProcess -or @($listener)[0].OwningProcess -ne $gatewayProcess.ProcessId)) {
        throw 'The gateway port belongs to another process. Nothing was stopped.'
    }
    if ($gatewayProcess) {
        Stop-Process -Id $gatewayProcess.ProcessId
        Wait-Process -Id $gatewayProcess.ProcessId -Timeout 5 -ErrorAction SilentlyContinue
    }
    $oldGatewayPort = $env:PHARMA_WEBHOOK_PORT
    $oldTomcatPort = $env:PHARMA_TOMCAT_PORT
    $runId = [Guid]::NewGuid().ToString('N')
    try {
        $env:PHARMA_WEBHOOK_PORT = [string]$saved.gatewayPort
        $env:PHARMA_TOMCAT_PORT = [string]$saved.tomcatPort
        $gatewayProcess = Start-Process -FilePath $saved.nodePath -ArgumentList @('"' + $gatewayScript + '"') -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $runtimeFolder "$runId-gateway.out.log") -RedirectStandardError (Join-Path $runtimeFolder "$runId-gateway.err.log")
        $saved.gatewayPid = $gatewayProcess.Id
        $saved | ConvertTo-Json | Set-Content -LiteralPath $stateFile -Encoding UTF8
    } finally {
        $env:PHARMA_WEBHOOK_PORT = $oldGatewayPort
        $env:PHARMA_TOMCAT_PORT = $oldTomcatPort
    }
    $deadline = (Get-Date).AddSeconds(8)
    $ready = $false
    do {
        try {
            $health = Invoke-RestMethod -Uri "http://127.0.0.1:$($saved.gatewayPort)/healthz" -TimeoutSec 1
            $ready = $health.service -eq 'PharmaFlow-SePay-webhook'
        } catch { Start-Sleep -Milliseconds 250 }
    } until ($ready -or (Get-Date) -ge $deadline -or $gatewayProcess.HasExited)
    if (!$ready) { throw 'Gateway failed to reload. The Cloudflare URL was not changed.' }
    Show-Status $saved
    return
}
if ($Action -eq 'Stop') {
    Stop-OwnedRuntime $saved
    Write-Output 'Stopped the owned PharmaFlow webhook processes, if running. Any saved URL is now inactive.'
    return
}
if ($saved) {
    $gatewayProcess = Get-OwnedProcess $saved.gatewayPid $saved.nodePath $saved.gatewayScript
    $tunnelProcess = Get-OwnedProcess $saved.tunnelPid $saved.cloudflaredPath $saved.tunnelLog
    if ($gatewayProcess -and $tunnelProcess -and (Test-PublicHealth $saved.healthUrl)) { Show-Status $saved; return }
    Stop-OwnedRuntime $saved
}
foreach ($executable in @($NodePath, $CloudflaredPath, $gatewayScript)) {
    if (!(Test-Path -LiteralPath $executable -PathType Leaf)) { throw "Missing file: $executable" }
}
if (Get-NetTCPConnection -State Listen -LocalPort $GatewayPort -ErrorAction SilentlyContinue) {
    throw "Gateway port $GatewayPort is occupied. Choose another GatewayPort."
}
# Confirm this Tomcat context exists before publishing its webhook.
$catalog = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:$TomcatPort/Pharma_Flow/products" -TimeoutSec 10
if ($catalog.StatusCode -ne 200) { throw 'PharmaFlow is not available on the selected Tomcat port.' }
New-Item -ItemType Directory -Path $runtimeFolder -Force | Out-Null
$runId = [Guid]::NewGuid().ToString('N')
$gatewayOut = Join-Path $runtimeFolder "$runId-gateway.out.log"
$gatewayErr = Join-Path $runtimeFolder "$runId-gateway.err.log"
$tunnelLog = Join-Path $runtimeFolder "$runId-tunnel.log"
$tunnelOut = Join-Path $runtimeFolder "$runId-tunnel.out.log"
$tunnelErr = Join-Path $runtimeFolder "$runId-tunnel.err.log"
# An isolated empty config prevents inheriting another project's tunnel ingress.
$isolatedConfig = Join-Path $runtimeFolder "$runId-cloudflared.yml"
Set-Content -LiteralPath $isolatedConfig -Value '# PharmaFlow Quick Tunnel; no credentials or ingress.' -Encoding Ascii
$state = [pscustomobject]@{
    gatewayPid = $null; tunnelPid = $null; gatewayScript = $gatewayScript
    nodePath = $NodePath; cloudflaredPath = $CloudflaredPath; tunnelLog = $tunnelLog
    webhookUrl = $null; healthUrl = $null; gatewayPort = $GatewayPort; tomcatPort = $TomcatPort
    startedAt = (Get-Date).ToString('o')
}
$oldGatewayPort = $env:PHARMA_WEBHOOK_PORT
$oldTomcatPort = $env:PHARMA_TOMCAT_PORT
try {
    $env:PHARMA_WEBHOOK_PORT = [string]$GatewayPort
    $env:PHARMA_TOMCAT_PORT = [string]$TomcatPort
    $gatewayProcess = Start-Process -FilePath $NodePath -ArgumentList @('"' + $gatewayScript + '"') -WindowStyle Hidden -PassThru -RedirectStandardOutput $gatewayOut -RedirectStandardError $gatewayErr
    $state.gatewayPid = $gatewayProcess.Id
    $deadline = (Get-Date).AddSeconds(10)
    $ready = $false
    do {
        try {
            $health = Invoke-RestMethod -Uri "http://127.0.0.1:$GatewayPort/healthz" -TimeoutSec 1
            $ready = $health.service -eq 'PharmaFlow-SePay-webhook'
        } catch { Start-Sleep -Milliseconds 250 }
    } until ($ready -or (Get-Date) -ge $deadline -or $gatewayProcess.HasExited)
    if (!$ready) { throw "Gateway failed to start. See $gatewayErr" }
    $arguments = @('tunnel', '--config', ('"' + $isolatedConfig + '"'), '--url', "http://127.0.0.1:$GatewayPort", '--no-autoupdate', '--protocol', $TunnelProtocol, '--metrics', '127.0.0.1:0', '--loglevel', 'info', '--logfile', ('"' + $tunnelLog + '"'))
    $tunnelProcess = Start-Process -FilePath $CloudflaredPath -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $tunnelOut -RedirectStandardError $tunnelErr
    $state.tunnelPid = $tunnelProcess.Id
    $state | ConvertTo-Json | Set-Content -LiteralPath $stateFile -Encoding UTF8
    $deadline = (Get-Date).AddSeconds(40)
    $publicUrl = $null
    do {
        Start-Sleep -Milliseconds 500
        if (Test-Path -LiteralPath $tunnelLog) {
            $log = Get-Content -LiteralPath $tunnelLog -Raw
            if ($log -match 'https://[a-z0-9-]+\.trycloudflare\.com') { $publicUrl = $Matches[0] }
        }
    } until ($publicUrl -or (Get-Date) -ge $deadline -or $tunnelProcess.HasExited)
    if (!$publicUrl) { throw "Cloudflare did not provide a URL. See $tunnelLog and $tunnelErr" }
    $state.webhookUrl = "$publicUrl/Pharma_Flow/payment/sepay/webhook"
    $state.healthUrl = "$publicUrl/healthz"
    $state | ConvertTo-Json | Set-Content -LiteralPath $stateFile -Encoding UTF8
    # A hostname alone is not proof that an edge connection was established.
    $deadline = (Get-Date).AddSeconds($ConnectTimeoutSeconds)
    $reachable = $false
    do {
        # An early lookup can cache NXDOMAIN while the hostname is provisioning.
        $registered = (Get-Content -LiteralPath $tunnelLog -Raw).Contains('Registered tunnel connection')
        if (!$registered) {
            $script:lastPublicHealthError = 'Waiting for Cloudflare edge registration.'
        } else {
            $dnsReady = Test-QuickTunnelDns $state.healthUrl
            if ($dnsReady -eq $false) {
                $script:lastPublicHealthError = 'Waiting for the new hostname DNS record.'
            } else {
                $reachable = Test-PublicHealth $state.healthUrl
            }
        }
        if (!$reachable) { Start-Sleep -Milliseconds 500 }
    } until ($reachable -or (Get-Date) -ge $deadline -or $tunnelProcess.HasExited)
    if (!$reachable) {
        throw "Public HTTPS health check failed: $script:lastPublicHealthError Do not use this URL in SePay. See $tunnelLog"
    }
    Show-Status $state
    Write-Output 'Verify the public health URL before configuring SePay. The URL changes after restart.'
} catch {
    Stop-OwnedRuntime $state
    throw
} finally {
    $env:PHARMA_WEBHOOK_PORT = $oldGatewayPort
    $env:PHARMA_TOMCAT_PORT = $oldTomcatPort
}
