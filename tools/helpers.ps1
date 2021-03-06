function Get-ShouldInstall()
{
    param (
        [Parameter(Mandatory = $true)]
        [string] $version
    )

    [array] $keys = Get-UninstallRegistryKey -SoftwareName 'XSplit Broadcaster'
    if ($keys.Length -ge 1)
    {
        return $keys[0].DisplayVersion -ne $version
    }
  
    return $true
}

function Get-RebootPending()
{
    return Test-Path -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending'
}
