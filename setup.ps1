<#
 Recreates the debian001 VM (WSL2 Debian) + signed apt repo.
 Run from PowerShell:  powershell -ExecutionPolicy Bypass -File C:\source\debian001\setup.ps1
 Options: -Name debian001  -Distro Debian  -Force (unregister existing VM first)
 No admin rights or Docker needed; uses WSL's official 'wsl --install Debian'.
#>
param(
    [string]$Name = 'debian001',
    [string]$Distro = 'Debian',   # see: wsl --list --online
    [string]$Root = $PSScriptRoot,
    [switch]$Force
)
$ErrorActionPreference = 'Stop'
$vmDir = Join-Path $Root 'vm'
$repo  = Join-Path $Root 'repo'

function Wsl-List { (wsl.exe -l -q 2>$null) -join "`n" -replace "`0", '' }

if ((Wsl-List) -split "`n" | Where-Object { $_.Trim() -eq $Name }) {
    if (-not $Force) { throw "WSL distro '$Name' already exists. Re-run with -Force to replace it (deletes the VM and its repo data)." }
    wsl.exe --unregister $Name | Out-Null
}

# --- install the official Debian WSL distro (from Microsoft's distro list) ---
New-Item -ItemType Directory -Force $vmDir, (Join-Path $repo 'incoming') | Out-Null
Write-Host "Installing official Debian as WSL distro '$Name' into $vmDir ..."
wsl.exe --install $Distro --name $Name --location $vmDir --web-download --no-launch
if ($LASTEXITCODE) { throw "wsl --install failed" }

# --- provision ---
$wslRepo = (wsl.exe -d $Name -u root -- wslpath -a ($repo -replace '\\', '/')) -replace "`0", ''
Write-Host "Provisioning from $wslRepo ..."
wsl.exe -d $Name -u root -- bash "$wslRepo/provision.sh"
if ($LASTEXITCODE) { throw "provision.sh failed" }

# restart so systemd (wsl.conf) takes effect, then start nginx
wsl.exe --terminate $Name
wsl.exe -d $Name -u root -- bash -c 'sleep 3; systemctl restart nginx; repo-upload; apt-get update 2>&1 | tail -3'

Write-Host "`nDone. Drop .deb files in $repo\incoming, then:  wsl -d $Name -u root repo-upload"
