  param(
    [Parameter(Mandatory)]
    [string]$TargetFile,
  
    [int[]]$Ports = @(80,443,8080,8443),
  
    [int]$ThrottleLimit = 50
)
  
  
  
$FixedVersions = @{
    "8.5" = [version]"8.5.12"
    "8.4" = [version]"8.4.27"
    "8.3" = [version]"8.3.36"
    "8.2" = [version]"8.2.35"
}
  
$CommonPaths = @(
    "/",
    "/index.php",
    "/phpinfo.php",
    "/info.php",
    "/test.php",
    "/server-status",
    "/status.php",
    "/admin.php",
    "/login.php",
    "/dashboard.php",
    "/wp-login.php",
    "/wp-admin/",
    "/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php",
    "/vendor/phpunit/phpunit/phpunit.xml",
    "/phpmyadmin/",
    "/pma/",
    "/adminer.php",
    "/api/",
    "/health.php",
    "/version.php"
)
  
function ConvertTo-UInt32 {
    param([System.Net.IPAddress]$IP)
  
    $Bytes = $IP.GetAddressBytes()
    [Array]::Reverse($Bytes)
    [BitConverter]::ToUInt32($Bytes,0)
}
  
function ConvertFrom-UInt32 {
    param([UInt32]$Value)
  
    $Bytes = [BitConverter]::GetBytes($Value)
    [Array]::Reverse($Bytes)
  
    ([System.Net.IPAddress]::new($Bytes)).ToString()
}
  
function Get-IPRange {
  
    param([string]$CIDR)
  
    if ($CIDR -notmatch "/") {
        return @($CIDR)
    }
  
    $IP,$Prefix = $CIDR.Split("/")
    $Prefix = [int]$Prefix
  
    if ($Prefix -lt 16) {
        Write-Warning "Skipping large range $CIDR (must be /16 or smaller)"
        return @()
    }
  
    $IPObj = [System.Net.IPAddress]$IP
    $IPInt = ConvertTo-UInt32 $IPObj
  
    $Mask = [uint32]::MaxValue -shl (32 - $Prefix)
  
    $Network   = $IPInt -band $Mask
    $Broadcast = $Network + ([math]::Pow(2,(32-$Prefix)) - 1)
  
    $Results = New-Object System.Collections.Generic.List[string]
  
    for ($i = $Network + 1; $i -lt $Broadcast; $i++) {
        $Results.Add((ConvertFrom-UInt32 $i))
    }
  
    return $Results
}
  
function Get-TargetInfo {
  
    param([string]$InputTarget)
  
    $InputTarget = $InputTarget.Trim()
  
    if ($InputTarget -match '^https?://') {
  
        try {
  
            $Uri = [System.Uri]$InputTarget
  
            return [PSCustomObject]@{
                Host   = $Uri.Host
                Port   = $Uri.Port
                Scheme = $Uri.Scheme
            }
  
        } catch {
            return $null
        }
    }
  
    if ($InputTarget -match '/') {
  
        return (Get-IPRange $InputTarget | ForEach-Object {
  
            [PSCustomObject]@{
                Host   = $_
                Port   = $null
                Scheme = $null
            }
  
        })
    }
  
    [PSCustomObject]@{
        Host   = $InputTarget
        Port   = $null
        Scheme = $null
    }
}
Get-Job | Stop-Job -Force
Get-Job | Remove-Job -Force
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " PHP2Shell Discovery Scanner" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
  
if (-not (Test-Path $TargetFile)) {
    Write-Error "Target file not found."
    exit
}
  
$Targets = [System.Collections.Generic.List[object]]::new()
  
Get-Content $TargetFile | ForEach-Object {
  
    $Line = $_.Trim()
  
    if ([string]::IsNullOrWhiteSpace($Line)) {
        return
    }
  
    if ($Line.StartsWith("#")) {
        return
    }
  
    $Parsed = Get-TargetInfo $Line
  
    if ($Parsed -is [Array]) {
  
        foreach ($Item in $Parsed) {
            $Targets.Add($Item)
        }
  
    } elseif ($Parsed) {
  
        $Targets.Add($Parsed)
    }
}
  
Write-Host "[+] Loaded $($Targets.Count) targets" -ForegroundColor Green
  
$ScanJobs = foreach ($Target in $Targets) {
  
    if ($Target.Port) {
  
        [PSCustomObject]@{
            Host   = $Target.Host
            Port   = $Target.Port
            Scheme = $Target.Scheme
        }
  
    } else {
  
        foreach ($Port in $Ports) {
  
            [PSCustomObject]@{
                Host   = $Target.Host
                Port   = $Port
                Scheme = $null
            }
        }
    }
}
  
$TotalJobs = $ScanJobs.Count
  
Write-Host ""
Write-Host "[+] Total scan jobs: $TotalJobs" -ForegroundColor Cyan
  
$ScanJobs = foreach ($Target in $Targets) {
  
   if ($Target.Port) {
  
       [PSCustomObject]@{
           Host   = $Target.Host
           Port   = $Target.Port
           Scheme = $Target.Scheme
       }
  
   } else {
  
       foreach ($Port in $Ports) {
  
           [PSCustomObject]@{
               Host   = $Target.Host
               Port   = $Port
               Scheme = $null
           }
       }
   }
}
  
$TotalJobs = $ScanJobs.Count
  
Write-Host ""
Write-Host "[DEBUG] Targets: $($Targets.Count)" -ForegroundColor Yellow
Write-Host "[DEBUG] ScanJobs: $($ScanJobs.Count)" -ForegroundColor Yellow
  
Write-Host ""
Write-Host "[+] Total scan jobs: $TotalJobs" -ForegroundColor Cyan
  
$Results = $ScanJobs | ForEach-Object -Parallel {
  
    Write-Host "[THREAD] $($_.Host):$($_.Port)" -ForegroundColor Gray
  
    $HostName = $_.Host
    $Port     = $_.Port
    $Scheme   = $_.Scheme
  
    $FixedVersions = @{
        "8.5" = [version]"8.5.12"
        "8.4" = [version]"8.4.27"
        "8.3" = [version]"8.3.36"
        "8.2" = [version]"8.2.35"
    }
  
    try {
  
        $Client = [System.Net.Sockets.TcpClient]::new()
  
        $Connect = $Client.BeginConnect(
            $HostName,
            $Port,
            $null,
            $null
        )
  
       if (-not $Connect.AsyncWaitHandle.WaitOne(1000)) {
  
    return [PSCustomObject]@{
        Host        = $HostName
        Port        = $Port
        URL         = $null
        PathFound   = $null
        PHPVersion  = $null
        Assessment  = "Unreachable"
        Server      = $null
    }
}
  
        $Client.EndConnect($Connect)
        $Client.Close()
  
        if (-not $Scheme) {
  
            $Scheme = if ($Port -in @(443,8443)) {
                "https"
            }
            else {
                "http"
            }
        }
  
        $Response = $null
$FoundPath = $null
  
foreach ($Path in $Using:CommonPaths) {
  
    $Url = "{0}://{1}:{2}{3}" -f `
        $Scheme,
        $HostName,
        $Port,
        $Path
  
    try {
  
        Write-Host "[SCAN] $HostName`:$Port" -ForegroundColor Cyan
  
        $Response = Invoke-WebRequest `
            -Uri $Url `
            -TimeoutSec 3 `
            -SkipCertificateCheck `
            -ErrorAction Stop
  
        $FoundPath = $Path
  
        Write-Host "[ALIVE] $Url" -ForegroundColor Green
        Write-Host "[SCAN] Testing common PHP paths..." -ForegroundColor Yellow
  
        break
  
    }
    catch {
        continue
    }
}
if (-not $Response) {
  
    return [PSCustomObject]@{
        Host        = $HostName
        Port        = $Port
        URL         = $Url
        PathFound   = $FoundPath
        PHPVersion  = $null
        Assessment  = "No Web Response"
        Server      = $null
    }
}
  
# Detect PHP even when version is hidden
$PHPDetected = $false
  
if ($Response.Headers["X-Powered-By"] -match "PHP") {
    $PHPDetected = $true
}
  
if ($Response.Content -match "PHP") {
    $PHPDetected = $true
}
  
$Version = $null
  
$PoweredBy = $Response.Headers["X-Powered-By"]
  
        if ($PoweredBy -match 'PHP\/([\d\.]+)') {
            $Version = $matches[1]
        }
  
if (-not $Version) {
  
    if ($PHPDetected) {
  
        return [PSCustomObject]@{
            Host        = $HostName
            Port        = $Port
            URL         = $Url
            PathFound   = $FoundPath
            PHPVersion  = "Unknown"
            Assessment  = "PHP Detected - Version Unknown"
            Server      = $Response.Headers["Server"]
        }
  
    } else {
  
        return [PSCustomObject]@{
            Host        = $HostName
            Port        = $Port
            URL         = $Url
            PathFound   = $FoundPath
            PHPVersion  = $null
            Assessment  = "No PHP Detected"
            Server      = $Response.Headers["Server"]
        }
  
    }
}
  
        $VerObj = [version]$Version
        $Branch = "$($VerObj.Major).$($VerObj.Minor)"
  
        
        # Any PHP version below 8.0
        if ($VerObj.Major -lt 8) {
  
            $Assessment = "Legacy Unsupported PHP"
  
        }
        # Supported branches we know how to assess
        elseif ($FixedVersions.ContainsKey($Branch)) {
  
            if ($VerObj -lt $FixedVersions[$Branch]) {
                $Assessment = "Potentially Vulnerable"
            }
            else {
                $Assessment = "Patched"
            }
  
        }
        # PHP 8.0 and 8.1 are EOL
        elseif (
            $VerObj.Major -eq 8 -and
            $VerObj.Minor -lt 2
        ) {
  
            $Assessment = "Legacy Unsupported PHP"
  
        }
        # Future / unknown branches
        else {
  
            $Assessment = "Unknown Branch"
        }
  
  
  
        if (
            $Assessment -eq "Potentially Vulnerable" -or
            $Assessment -eq "Legacy Unsupported PHP"
        ) {
  
            Write-Host ""
            Write-Host "[!!!] PHP2SHELL CANDIDATE FOUND" -ForegroundColor Red
            Write-Host "Host       : $HostName" -ForegroundColor Yellow
            Write-Host "Port       : $Port" -ForegroundColor Yellow
            Write-Host "PHP Version: $Version" -ForegroundColor Yellow
            Write-Host "Assessment : $Assessment" -ForegroundColor Red
            Write-Host ""
        }
  
    [PSCustomObject]@{
    Host        = $HostName
    Port        = $Port
    URL         = $Url
    PathFound   = $FoundPath
    PHPVersion  = $Version
    Assessment  = $Assessment
    Server      = $Response.Headers["Server"]
}
  
    } catch {
    }
  
} -ThrottleLimit $ThrottleLimit
  
$Results |
    Sort-Object Host,Port |
    Export-Csv `
        ".\PHP2Shell_Assessment.csv" `
        -NoTypeInformation `
        -Encoding UTF8
  
$Potential = $Results | Where-Object {
    $_.Assessment -eq "Potentially Vulnerable" -or
    $_.Assessment -eq "Legacy Unsupported PHP"
}
  
Write-Host ""
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host " SCAN COMPLETE" -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""
  
Write-Host "Findings      : $($Results.Count)" -ForegroundColor Green
Write-Host "Vulnerable    : $($Potential.Count)" -ForegroundColor Red
Write-Host "CSV Exported  : PHP2Shell_Assessment.csv" -ForegroundColor Cyan 
  
 

