$ErrorActionPreference = 'Stop'

Confirm-Win10 -ReqBuild 14393

$toolsDir = "$(Split-Path -Parent $MyInvocation.MyCommand.Definition)"
. $toolsDir\helpers.ps1

$softwareName = 'XSplit Broadcaster'
[version] $softwareVersion = '4.5.2408.2201'
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
    url64bit       = 'https://cdn2.xsplit.com/download/bc/m54/4.5.2408.2201/XSplit_Broadcaster_4.5.2408.2201.exe'
    checksum64     = '67ca6ca7bf221e178a0098819c45e2c5313505776803ac5242422884f960c074'
    checksumType64 = 'sha256'
    silentArgs     = "/exenoui /noprereqs /exelog `"$logFilePathPrefix.ExeInstall.log`" /qn /norestart /l*v `"$logFilePathPrefix.MsiInstall.log`""
    validExitCodes = @(0, 3010, 1641)
  }

  Install-ChocolateyPackage @packageArgs
}
