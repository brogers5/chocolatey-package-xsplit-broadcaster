function Get-CurrentVersion {
    [array] $keys = Get-UninstallRegistryKey -SoftwareName 'XSplit Broadcaster'
    if ($keys.Length -ge 1) {
        return [version] $keys[0].DisplayVersion
    }
  
    return $null
}
