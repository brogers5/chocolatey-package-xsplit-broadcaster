$ErrorActionPreference = 'Stop'

$softwareName = 'XSplit Broadcaster'
$installLocation = Get-AppInstallLocation -AppNamePattern $softwareName

if ($null -ne $installLocation) {
    $installLocationPattern = "$([regex]::Escape($installLocation)).*"

    $processes = Get-Process
    $detectedProcesses = New-Object Collections.Generic.List[PSObject]
    foreach ($process in $processes) {
        if ($process.Path -match $installLocationPattern) {
            $detectedProcesses.Add($process)
        }
    }
    
    if ($detectedProcesses.Count -gt 0) {
        Write-Warning "$softwareName is currently running, stopping it to prevent upgrade/uninstall from blocking..."
        Write-Warning 'The following processes were detected and will be stopped:'
    
        foreach ($process in $detectedProcesses) {
            Write-Warning "  - $($process.ProcessName) (PID: $($process.Id))"
        }
    
        Remove-Process -PathFilter $installLocationPattern | Out-Null
    }
}
else {
    Write-Warning "Could not detect install location of $softwareName"
    Write-Warning 'If any related processes are running, they may need to be manually closed for upgrade/uninstall to proceed'
}
