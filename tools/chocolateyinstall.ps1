﻿$ErrorActionPreference = 'Stop'

Confirm-Win10 -ReqBuild 14393

$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
. $toolsDir\helpers.ps1

$softwareName = 'XSplit Broadcaster'
[version] $softwareVersion = '4.5.2311.2102'
$currentVersion = Get-CurrentVersion

if ($currentVersion -and $currentVersion -eq $softwareVersion -and !$env:ChocolateyForce) {
  Write-Output "$softwareName v$softwareVersion is already installed."
  Write-Output 'Skipping download and execution of installer.'
}
else {
  if (Get-PendingReboot) {
    Write-Warning "A pending system reboot request has been detected. If this
         request originated from installing .NET Framework 4.8,
         $softwareName may fail to install."
  }

  $logFilePathPrefix = "$($env:TEMP)\$($packageName).$($env:chocolateyPackageVersion)"

  $packageArgs = @{
    packageName    = $env:ChocolateyPackageName
    softwareName   = $softwareName
    fileType       = 'EXE'
    url64bit       = 'https://cdn2.xsplit.com/download/bc/m51/4.5.2311.2102/XSplit_Broadcaster_4.5.2311.2102.exe'
    checksum64     = '7356ade7e9f2ead8acde9a8ab663aba8fabe205768f08a29c7f392ae8cb47f10'
    checksumType64 = 'sha256'
    silentArgs     = "/exenoui /noprereqs /exelog `"$logFilePathPrefix.ExeInstall.log`" /qn /norestart /l*v `"$logFilePathPrefix.MsiInstall.log`""
    validExitCodes = @(0, 3010, 1641)
  }

  Install-ChocolateyPackage @packageArgs
}
