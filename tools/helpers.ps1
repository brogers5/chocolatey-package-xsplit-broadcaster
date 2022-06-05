function Get-ShouldInstall()
{
    param (
        [Parameter(Mandatory = $true)]
        [string] $version
    )

    [array] $key = Get-UninstallRegistryKey -SoftwareName $softwareName
    if ($key.Length -ge 1)
    {
        return $key.Version -eq $version
    }
  
    return $true
}
