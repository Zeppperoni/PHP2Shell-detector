# PHP2Shell Discovery Scanner

A multithreaded PowerShell 7 scanner for identifying web servers running potentially vulnerable or unsupported PHP versions associated with:

- CVE-2026-109618
- CVE-2026-109619

The scanner supports:

- Individual IP addresses
- Hostnames
- URLs
- CIDR ranges (/16, /24, etc.)
- HTTP and HTTPS
- Parallel scanning
- CSV reporting
- Common PHP path discovery
- Detection of unsupported PHP versions (< 8.0)
- Detection of EOL PHP 8.0 and 8.1 installations

---

# Features

✅ Scan individual hosts

✅ Scan large CIDR ranges

✅ Scan URLs directly

✅ Checks common PHP endpoints

✅ Detects exposed PHP version information

✅ Identifies vulnerable and unsupported PHP installations

✅ Exports findings to CSV

✅ Multithreaded scanning

✅ SSL/TLS support

---

# Requirements

- PowerShell 7.x or later
- Windows, Linux, or macOS
- Network connectivity to target systems

Verify your version:

```powershell
$PSVersionTable.PSVersion
```

Example:

```text
Major Minor Patch
----- ----- -----
7     4     6
```

---

# Installation

Clone the repository:

```bash
git clone https://github.com/your-org/PHP2Shell-Scanner.git
cd PHP2Shell-Scanner
```

Or download:

```text
PHP2Shell-Scanner.ps1
```

directly from GitHub.

---

# Supported Input Types

The scanner accepts mixed targets within the same file.

## IP Addresses

```text
10.0.0.10
10.0.0.11
192.168.1.100
```

## Hostnames

```text
web01.company.com
portal.contoso.com
```

## URLs

```text
https://portal.company.com
http://intranet.company.com
https://10.0.0.15
```

## CIDR Ranges

```text
10.0.0.0/24
192.168.100.0/24
172.16.0.0/16
```

---

# Creating a Target File

Example:

```text
# Internal web servers
10.0.0.0/24

# External applications
portal.company.com
https://vpn.company.com

# Individual systems
10.10.10.10
```

Save as:

```text
targets.txt
```

---

# Basic Usage

```powershell
.\PHP2Shell-Scanner.ps1 -TargetFile .\targets.txt
```

---

# Custom Ports

Default ports:

```text
80
443
8080
8443
```

Specify custom ports:

```powershell
.\PHP2Shell-Scanner.ps1 `
    -TargetFile .\targets.txt `
    -Ports 80,443,8080,8443,9000
```

---

# Adjusting Scan Speed

Default:

```powershell
-ThrottleLimit 50
```

Example:

```powershell
.\PHP2Shell-Scanner.ps1 `
    -TargetFile .\targets.txt `
    -ThrottleLimit 200
```

### Recommended Values

| Environment | Throttle |
|------------|----------|
| Laptop | 50 |
| Workstation | 100 |
| High-End Workstation | 200 |
| Server | 250-500 |

---

# Example Scan

```powershell
.\PHP2Shell-Scanner.ps1 `
    -TargetFile .\targets.txt `
    -ThrottleLimit 100
```

Output:

```text
=========================================
 PHP2Shell Discovery Scanner
=========================================

[+] Loaded 6144 targets

[+] Total scan jobs: 24576

[SCAN] 10.0.0.10:443
[ALIVE] https://10.0.0.10:443

[SCAN] Testing common PHP paths...
```

---

# Findings

When a potentially vulnerable PHP installation is discovered:

```text
[!!!] PHP2SHELL CANDIDATE FOUND

Host       : 10.0.0.10
Port       : 443
PHP Version: 8.2.20
Assessment : Potentially Vulnerable
```

---

# Assessment Logic

## Potentially Vulnerable

PHP version is older than the known fixed release:

| Branch | Fixed Version |
|----------|---------------|
| 8.2 | 8.2.35 |
| 8.3 | 8.3.36 |
| 8.4 | 8.4.27 |
| 8.5 | 8.5.12 |

---

## Legacy Unsupported PHP

Any PHP version:

```text
< 8.0
```

or

```text
8.0.x
8.1.x
```

---

## Patched

A version equal to or newer than the fixed branch release.

Example:

```text
PHP 8.3.36
PHP 8.4.27
PHP 8.5.12
```

---

## Unknown Branch

Future PHP versions not yet included in scanner logic.

Example:

```text
PHP 8.6.x
PHP 9.x
```

---

# Common Paths Checked

```text
/
/index.php
/phpinfo.php
/info.php
/test.php
/server-status
/status.php
/admin.php
/login.php
/dashboard.php
/wp-login.php
/wp-admin/
/phpmyadmin/
/pma/
/adminer.php
/api/
/health.php
/version.php
/vendor/phpunit/phpunit/src/Util/PHP/eval-stdin.php
/vendor/phpunit/phpunit/phpunit.xml
```

---

# CSV Export

Results are automatically exported:

```text
PHP2Shell_Assessment.csv
```

Columns:

```text
Host
Port
URL
PathFound
PHPVersion
Assessment
Server
```

---

# Example CSV

```csv
Host,Port,URL,PHPVersion,Assessment
10.0.0.10,443,https://10.0.0.10,8.2.20,Potentially Vulnerable
10.0.0.11,443,https://10.0.0.11,8.3.36,Patched
```

---

# Troubleshooting

## Script hangs

Reduce:

```powershell
-ThrottleLimit
```

Example:

```powershell
-ThrottleLimit 25
```

---

## No results found

Verify connectivity:

```powershell
Test-NetConnection 10.0.0.10 -Port 443
```

---

## Parsing errors

Confirm PowerShell 7:

```powershell
$PSVersionTable.PSVersion
```

PowerShell 5.1 does not support:

```powershell
ForEach-Object -Parallel
```

---

## Clear Existing Jobs

Before scanning:

```powershell
Get-Job | Stop-Job -Force
Get-Job | Remove-Job -Force
```

---

# Legal Notice

This tool is intended for authorized security testing, vulnerability assessment, and asset inventory activities. Only scan networks, systems, and applications for which you have explicit authorization.

Unauthorized scanning may violate organizational policies, contracts, or applicable laws.

---

# Author

Internal Security Assessment Utility

Manager, Information Technology Security, Privacy & Compliance
