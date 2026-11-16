param(
    [string]$TomcatBase = (Join-Path (Split-Path -Parent $PSScriptRoot) 'build\tomcat-preview'),
    [string]$TomcatHome = 'C:\Program Files\Apache Software Foundation\Tomcat 10.1',
    [string]$JavaPath = 'C:\Program Files\Java\jdk-17\bin\java.exe',
    [string]$SePayConfigPath = (Join-Path $env:LOCALAPPDATA 'PharmaFlow\payments\sepay.clixml'),
    [switch]$Restart
)
$ErrorActionPreference = 'Stop'
$projectFolder = Split-Path -Parent $PSScriptRoot
$webRoot = (Resolve-Path -LiteralPath (Join-Path $projectFolder 'build\web')).Path
$baseConfig = Join-Path $TomcatBase 'conf\server.xml'
if (!(Test-Path -LiteralPath $baseConfig)) {
    $buildFolder = [IO.Path]::GetFullPath((Join-Path $projectFolder 'build')) + [IO.Path]::DirectorySeparatorChar
    $resolvedBase = [IO.Path]::GetFullPath($TomcatBase)
    if (!$resolvedBase.StartsWith($buildFolder, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'A new preview base must be created inside this project build folder.'
    }
    foreach ($folder in @('conf', 'logs', 'temp', 'work', 'webapps')) {
        New-Item -ItemType Directory -Path (Join-Path $resolvedBase $folder) -Force | Out-Null
    }
    foreach ($name in @('web.xml', 'catalina.properties', 'logging.properties')) {
        $destination = Join-Path $resolvedBase "conf\$name"
        if (!(Test-Path -LiteralPath $destination)) {
            Copy-Item -LiteralPath (Join-Path $TomcatHome "conf\$name") -Destination $destination
        }
    }
    $escapedWebRoot = [Security.SecurityElement]::Escape($webRoot.Replace('\', '/'))
    @"
<?xml version="1.0" encoding="UTF-8"?>
<Server port="-1">
  <Service name="Catalina">
    <Connector address="127.0.0.1" port="18080" protocol="HTTP/1.1" connectionTimeout="20000" />
    <Engine name="Catalina" defaultHost="localhost">
      <Host name="localhost" appBase="webapps" unpackWARs="false" autoDeploy="false" deployOnStartup="false">
        <Context path="/Pharma_Flow" docBase="$escapedWebRoot" reloadable="false" />
      </Host>
    </Engine>
  </Service>
</Server>
"@ | Set-Content -LiteralPath $baseConfig -Encoding UTF8
}
$TomcatBase = (Resolve-Path -LiteralPath $TomcatBase).Path
[xml]$serverConfig = Get-Content -LiteralPath (Join-Path $TomcatBase 'conf\server.xml') -Raw
$connector = @($serverConfig.Server.Service.Connector | Where-Object { $_.port -eq '18080' -and $_.address -eq '127.0.0.1' })
$context = @($serverConfig.Server.Service.Engine.Host.Context | Where-Object { $_.path -eq '/Pharma_Flow' })
if ($connector.Count -ne 1 -or $context.Count -ne 1 -or
        (Resolve-Path -LiteralPath $context.docBase).Path -ne $webRoot) {
    throw 'This base must point to this project build/web, bound to 127.0.0.1:18080.'
}
foreach ($required in @($JavaPath, (Join-Path $TomcatHome 'bin\bootstrap.jar'), (Join-Path $TomcatHome 'bin\tomcat-juli.jar'))) {
    if (!(Test-Path -LiteralPath $required -PathType Leaf)) { throw "Missing file: $required" }
}
$listener = Get-NetTCPConnection -LocalPort 18080 -State Listen -ErrorAction SilentlyContinue
if ($listener) {
    $owner = Get-CimInstance Win32_Process -Filter "ProcessId = $([int]@($listener)[0].OwningProcess)"
    if (!$owner -or $owner.ExecutablePath -ne $JavaPath -or
            $owner.CommandLine.IndexOf($TomcatBase, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
        throw 'Port 18080 belongs to another process. Nothing was stopped.'
    }
    if (!$Restart) {
        $response = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:18080/Pharma_Flow/products' -TimeoutSec 10
        Write-Output "Existing PharmaFlow preview: HTTP $([int]$response.StatusCode)"
        return
    }
    Stop-Process -Id $owner.ProcessId
    $stopDeadline = (Get-Date).AddSeconds(5)
    do {
        Start-Sleep -Milliseconds 250
        $listener = Get-NetTCPConnection -LocalPort 18080 -State Listen -ErrorAction SilentlyContinue
    } until (!$listener -or (Get-Date) -ge $stopDeadline)
    if ($listener) { throw 'The owned preview has not released port 18080 yet.' }
}
$runId = [Guid]::NewGuid().ToString('N')
$outputLog = Join-Path $TomcatBase "logs\preview-$runId-stdout.log"
$errorLog = Join-Path $TomcatBase "logs\preview-$runId-stderr.log"
$javaArguments = @(
    ('"-Dcatalina.home=' + $TomcatHome + '"'),
    ('"-Dcatalina.base=' + $TomcatBase + '"'),
    ('"-Djava.io.tmpdir=' + (Join-Path $TomcatBase 'temp') + '"'),
    ('"-Djava.util.logging.config.file=' + (Join-Path $TomcatBase 'conf\logging.properties') + '"'),
    '-Djava.util.logging.manager=org.apache.juli.ClassLoaderLogManager',
    '-Dfile.encoding=UTF-8',
    '--add-opens=java.base/java.lang=ALL-UNNAMED',
    '--add-opens=java.base/java.io=ALL-UNNAMED',
    '-classpath',
    ('"' + (Join-Path $TomcatHome 'bin\bootstrap.jar') + ';' + (Join-Path $TomcatHome 'bin\tomcat-juli.jar') + '"'),
    'org.apache.catalina.startup.Bootstrap', 'start'
)
$savedEnvironment = @{}
try {
    # Explicit process credentials take priority over the optional local profile.
    if (!$env:SEPAY_WEBHOOK_SECRET -and (Test-Path -LiteralPath $SePayConfigPath)) {
        $settings = Import-Clixml -LiteralPath $SePayConfigPath
        if ($settings.Enabled -eq $true) {
            if ($settings.AccountNumber -notmatch '^[A-Za-z0-9]{1,19}$' -or
                    ($settings.VaAccount -and $settings.VaAccount -notmatch '^[A-Za-z0-9]{1,19}$') -or
                    $settings.BankCode -notmatch '^[A-Za-z0-9]{1,20}$' -or $settings.Gateway -notmatch '^[A-Za-z0-9]{1,40}$' -or
                    $settings.WebhookSecret -isnot [Security.SecureString] -or $settings.WebhookSecret.Length -lt 32) {
                throw 'Invalid local SePay profile. Run tools/configure-sepay.ps1 again.'
            }
            $secretPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($settings.WebhookSecret)
            try {
                $profileValues = @{
                    SEPAY_ACCOUNT_NUMBER = $settings.AccountNumber
                    SEPAY_VA_ACCOUNT = $settings.VaAccount
                    SEPAY_ACCOUNT_NAME = $settings.AccountName
                    SEPAY_BANK_CODE = $settings.BankCode
                    SEPAY_GATEWAY = $settings.Gateway
                    SEPAY_WEBHOOK_SECRET = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($secretPointer)
                }
                foreach ($name in $profileValues.Keys) {
                    $savedEnvironment[$name] = [Environment]::GetEnvironmentVariable($name, 'Process')
                    [Environment]::SetEnvironmentVariable($name, $profileValues[$name], 'Process')
                }
            } finally {
                [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($secretPointer)
                $profileValues = $null
            }
        }
    }
    $previewProcess = Start-Process -FilePath $JavaPath -ArgumentList $javaArguments -WorkingDirectory $TomcatBase -WindowStyle Hidden -PassThru -RedirectStandardOutput $outputLog -RedirectStandardError $errorLog
} finally {
    foreach ($name in $savedEnvironment.Keys) {
        [Environment]::SetEnvironmentVariable($name, $savedEnvironment[$name], 'Process')
    }
}
try {
    $previewProcess.Id | Set-Content -LiteralPath (Join-Path (Split-Path -Parent $TomcatBase) 'tomcat.pid')
    $deadline = (Get-Date).AddSeconds(30)
    $ready = $false
    do {
        try {
            $response = Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:18080/Pharma_Flow/products' -TimeoutSec 2
            $ready = $response.StatusCode -eq 200
        } catch { Start-Sleep -Milliseconds 500 }
    } until ($ready -or (Get-Date) -ge $deadline -or $previewProcess.HasExited)
    if (!$ready) { throw "Preview failed to start. See $errorLog" }
    Write-Output "PharmaFlow ready: http://127.0.0.1:18080/Pharma_Flow/products (PID $($previewProcess.Id))"
} catch {
    if (!$previewProcess.HasExited) { Stop-Process -Id $previewProcess.Id }
    throw
}
