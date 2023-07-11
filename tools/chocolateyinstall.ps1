$ErrorActionPreference = 'Stop'

Confirm-Win10 14393

$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
. $toolsDir\helpers.ps1

$softwareName = 'XSplit Broadcaster'
[version] $softwareVersion = '4.4.2304.1203'
$currentVersion = Get-CurrentVersion

if ($currentVersion -and $currentVersion -eq $softwareVersion -and !$env:ChocolateyForce) {
  Write-Output "$softwareName v$softwareVersion is already installed."
  Write-Output "Skipping download and execution of installer."
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
    url64bit       = 'https://cdn2.xsplit.com/download/bc/m50/4.4.2304.1203/XSplit_Broadcaster_4.4.2304.1203.exe'
    checksum64     = '750a8857c8b7b0ba2f6181c7bf4142b9eb4afad3c9c1a7adbd1a09b1091e06b1'
    checksumType64 = 'sha256'
    silentArgs     = "/exenoui /noprereqs /exelog `"$logFilePathPrefix.ExeInstall.log`" /qn /norestart /l*v `"$logFilePathPrefix.MsiInstall.log`""
    validExitCodes = @(0, 3010, 1641)
  }

  Install-ChocolateyPackage @packageArgs
}
