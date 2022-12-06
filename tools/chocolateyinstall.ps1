$ErrorActionPreference = 'Stop'

Confirm-Win10 14393

$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
. $toolsDir\helpers.ps1

$softwareName = 'XSplit Broadcaster'
$softwareVersion = '4.4.2211.0404'
$shouldInstall = Get-ShouldInstall -Version $softwareVersion

if (!$shouldInstall -and !$env:ChocolateyForce)
{
  Write-Output "$softwareName v$softwareVersion is already installed."
  Write-Output "Skipping download and execution of installer."
}
else
{
  if (Get-PendingReboot)
  {
    Write-Warning "A pending system reboot request has been detected. If this
         request originated from installing .NET Framework 4.8,
         $softwareName may fail to install."
  }

  $logFilePathPrefix = "$($env:TEMP)\$($packageName).$($env:chocolateyPackageVersion)"

  $packageArgs = @{
    packageName    = $env:ChocolateyPackageName
    softwareName   = $softwareName
    fileType       = 'EXE'
    url64bit       = 'https://cdn2.xsplit.com/download/bc/m48/4.4.2211.0404/XSplit_Broadcaster_4.4.2211.0404.exe'
    checksum64     = '4610e07d0f106a8caba3ffdd4bcb2ded10af89e32be15b54b2e08e5f78626111'
    checksumType64 = 'sha256'
    silentArgs     = "/exenoui /noprereqs /exelog `"$logFilePathPrefix.ExeInstall.log`" /qn /norestart /l*v `"$logFilePathPrefix.MsiInstall.log`""
    validExitCodes = @(0, 3010, 1641)
  }

  Install-ChocolateyPackage @packageArgs
}
