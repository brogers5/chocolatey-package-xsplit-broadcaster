$ErrorActionPreference = 'Stop'

Confirm-Win10 14393

$toolsDir = "$(Split-Path -parent $MyInvocation.MyCommand.Definition)"
. $toolsDir\helpers.ps1

$softwareName = 'XSplit Broadcaster'
$softwareVersion = '4.4.2209.2103'
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
    url64bit       = 'https://cdn2.xsplit.com/download/bc/m48/4.4.2209.2103/XSplit_Broadcaster_4.4.2209.2103.exe'
    checksum64     = '8305e6e3172c9e6ca10b49747a28478d4e61fb80ca7e8fbe4d9328e299a4e234'
    checksumType64 = 'sha256'
    silentArgs     = "/exenoui /noprereqs /exelog `"$logFilePathPrefix.ExeInstall.log`" /qn /norestart /l*v `"$logFilePathPrefix.MsiInstall.log`""
    validExitCodes = @(0, 3010, 1641)
  }

  Install-ChocolateyPackage @packageArgs
}
