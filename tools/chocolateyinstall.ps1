﻿$ErrorActionPreference = 'Stop'

Confirm-Win10 -ReqBuild 14393

$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
. $toolsDir\helpers.ps1

$softwareName = 'XSplit Broadcaster'
[version] $softwareVersion = '4.5.2405.1812'
$currentVersion = Get-CurrentVersion

if ($currentVersion -eq $softwareVersion -and !$env:ChocolateyForce) {
  Write-Output "$softwareName v$softwareVersion is already installed."
  Write-Output 'Skipping download and execution of installer.'
}
else {
  if (Get-PendingReboot) {
    Write-Warning "A pending system reboot request has been detected. If this
         request originated from installing .NET Framework 4.8,
         $softwareName may fail to install."
  }

  if ($currentVersion -gt $softwareVersion) {
    Write-Output "Current installed version (v$currentVersion) must be uninstalled first..."
    Uninstall-CurrentVersion
  }

  $logFilePathPrefix = "$($env:TEMP)\$($packageName).$($env:chocolateyPackageVersion)"

  $packageArgs = @{
    packageName    = $env:ChocolateyPackageName
    softwareName   = $softwareName
    fileType       = 'EXE'
    url64bit       = 'https://cdn2.xsplit.com/download/bc/m53/4.5.2405.1812/XSplit_Broadcaster_4.5.2405.1812.exe'
    checksum64     = 'f366dbce5fa3ae738c0c77465e0a169a7ae793bfbf39dfd1fc188db138bae3a5'
    checksumType64 = 'sha256'
    silentArgs     = "/exenoui /noprereqs /exelog `"$logFilePathPrefix.ExeInstall.log`" /qn /norestart /l*v `"$logFilePathPrefix.MsiInstall.log`""
    validExitCodes = @(0, 3010, 1641)
  }

  Install-ChocolateyPackage @packageArgs
}
