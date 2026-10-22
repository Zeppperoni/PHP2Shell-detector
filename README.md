# CVE-2026-109618-CVE-2026-109619

This script:
Scans common web ports (80, 443, 8080, 8443)
Attempts to identify PHP via HTTP headers and common PHP files
Extracts the version where possible
Flags potentially vulnerable versions
Does not exploit the vulnerability

```
$Targets = @(
    "10.10.1.25",
    "10.10.1.50",
    "webapp01.corp.local"
)
```
.\Check-PHP2Shell.ps1 -Targets $Targets

Faster Enterprise Sweep
If you already have an asset list:

$Targets = Get-Content .\servers.txt

.\Check-PHP2Shell.ps1 -Targets $Targets


Vulnerable Version Criteria

Flag as potentially vulnerable when PHP is below:

8.5.12
8.4.27
8.3.36
8.2.35

Any PHP 8.1 or older instance should be reviewed carefully because upstream support has ended, although some vendors may provide backported fixes.

For internal vulnerability management, I'd recommend combining this with an authenticated SSH/WinRM check that runs php -v directly on servers where possible, since many environments intentionally suppress PHP version disclosure in HTTP headers.
