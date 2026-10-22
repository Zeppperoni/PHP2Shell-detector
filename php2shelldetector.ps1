# Internal PHP Version Assessment
# Checks for PHP versions potentially vulnerable to:
# CVE-2026-109618 / CVE-2026-109619 (PHP2Shell)

param(
    [string[]]$Targets,
    [int[]]$Ports = @(80,443,8080,8443)
)

$FixedVersions = @{
    "8.5" = [version]"8.5.12"
    "8.4" = [version]"8.4.27"
    "8.3" = [version]"8.3.36"
    "8.2" = [version]"8.2.35"
}

function Test-PHPVersion {
    param([string]$VersionString)

    try {
        $Version = [version]$VersionString

        $Branch = "$($Version.Major).$($Version.Minor)"

        if ($FixedVersions.ContainsKey($Branch)) {
            if ($Version -lt $FixedVersions[$Branch]) {
                return "Potentially Vulnerable"
            }
            else {
                return "Patched"
            }
        }

        if ($Version.Major -lt 8 -or ($Version.Major -eq 8 -and $Version.Minor -lt 2)) {
            return "Legacy PHP - Review"
        }

        return "Unknown Branch"
    }
    catch {
        return "Unable to Parse"
    }
}

$Results = @()

foreach ($Target in $Targets) {

    foreach ($Port in $Ports) {

        $Scheme = if ($Port -eq 443 -or $Port -eq 8443) { "https" } else { "http" }

        $Urls = @(
            "$Scheme://$Target`:$Port/",
            "$Scheme://$Target`:$Port/phpinfo.php",
            "$Scheme://$Target`:$Port/info.php"
        )

        foreach ($Url in $Urls) {

            try {

                Write-Host "Checking $Url" -ForegroundColor Cyan

                $Response = Invoke-WebRequest `
                    -Uri $Url `
                    -UseBasicParsing `
                    -TimeoutSec 5 `
                    -ErrorAction Stop

                $ServerHeader = $Response.Headers["Server"]
                $PoweredBy = $Response.Headers["X-Powered-By"]

                $Version = $null

                if ($PoweredBy -match 'PHP\/([\d\.]+)') {
                    $Version = $matches[1]
                }
                elseif ($Response.Content -match 'PHP Version\s+([\d\.]+)') {
                    $Version = $matches[1]
                }

                $Status = if ($Version) {
                    Test-PHPVersion $Version
                }
                else {
                    "PHP Not Confirmed"
                }

                $Results += [PSCustomObject]@{
                    Host        = $Target
                    Port        = $Port
                    URL         = $Url
                    Server      = $ServerHeader
                    PHPVersion  = $Version
                    Assessment  = $Status
                }

                break
            }
            catch {
                continue
            }
        }
    }
}

$Results | Format-Table -AutoSize
$Results | Export-Csv ".\PHP2Shell_Assessment.csv" -NoTypeInformation

Write-Host "`nResults exported to PHP2Shell_Assessment.csv" -ForegroundColor Green
