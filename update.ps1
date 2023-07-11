Import-Module au

$userAgent = "Update checker of Chocolatey Community Package 'xsplit-broadcaster'"

function global:au_BeforeUpdate ($Package) {
    #Archive this version for future development, since the vendor does not guarantee perpetual availability
    $filePath = ".\XSplit_Broadcaster_$($Latest.Version).exe"
    Invoke-WebRequest -Uri $Latest.URL64 -OutFile $filePath
    $Latest.Checksum64 = (Get-FileHash -Path $filePath -Algorithm SHA256).Hash.ToLower()

    $readmePath = ".\DESCRIPTION.md"
    $readmeContents = Get-Content $readmePath -Encoding UTF8
    $readmeContents = $readmeContents -replace "/blob/v.*\/", "/blob/v$($Latest.Version)/"

    $encoding = New-Object System.Text.UTF8Encoding($false)
    $output = $readmeContents | Out-String
    [System.IO.File]::WriteAllText((Get-Item $readmePath).FullName, $output, $encoding)

    Set-DescriptionFromReadme -Package $Package -ReadmePath $readmePath
}

function global:au_AfterUpdate ($Package) {

}

function global:au_SearchReplace {
    @{
        'tools\chocolateyInstall.ps1'   = @{
            '(^\[version\] [$]softwareVersion\s*=\s*)(''.*'')' = "`$1'$($Latest.SoftwareVersion)'"
            "(^[$]?\s*url64bit\s*=\s*)('.*')"                  = "`$1'$($Latest.URL64)'"
            "(^[$]?\s*checksum64\s*=\s*)('.*')"                = "`$1'$($Latest.Checksum64)'"
        }
        "$($Latest.PackageName).nuspec" = @{
            "(<packageSourceUrl>)[^<]*(</packageSourceUrl>)" = "`$1https://github.com/brogers5/chocolatey-package-$($Latest.PackageName)/tree/v$($Latest.Version)`$2"
            "(\<releaseNotes\>).*?(\</releaseNotes\>)"       = "`${1}$($Latest.ReleaseNotes)`$2"
            "(<copyright>)[^<]*(</copyright>)"               = "`$1© $(Get-Date -Format yyyy) SplitmediaLabs, Ltd. All Rights Reserved.`$2"
        }
    }
}

function Get-LatestPublicReleaseData {
    $canonicalUri = 'https://www.xsplit.com/api/service/download?page_size=10&application_id=1&active=1&release=0&platform=windows&installer_type=exe'

    $response = Invoke-RestMethod -Uri $canonicalUri -UserAgent $userAgent -UseBasicParsing

    return $response.data[0]
}

function Get-OfflineInstallerUri([uri] $WebInstallerUri) {
    #The package uses the offline installer, but SplitMediaLabs only publishes the web installer's URI.
    #This is only publicly shared via the web installer, and exposed as an alternate location in the installer.
    $webInstallerUriSegments = $WebInstallerUri.Segments
    $downloadUrlDirectory = $WebInstallerUri.AbsoluteUri.TrimEnd($webInstallerUriSegments[$webInstallerUriSegments.Length - 1])
    $version = $webInstallerUriSegments[4].TrimEnd('/')

    #SplitMediaLabs sometimes puts the web installer in a different directory than the offline installer.
    #Probe the server to confirm we have a valid URL before returning it.
    $sameDirectoryUri = "$($downloadUrlDirectory)XSplit_Broadcaster_$version.exe"

    $returnedUri = $null
    try {
        Invoke-WebRequest -Uri $sameDirectoryUri -Method Head -UserAgent $userAgent | Out-Null
        $returnedUri = $sameDirectoryUri
    }
    catch {
        if ($_.Exception.Response.StatusCode.Value__ -eq 404) {
            #Assuming we have a web installer within a "/1/" directory. Remove this from the path.
            $sameDirectoryUriSegments = ([uri] $sameDirectoryUri).Segments
            $differentDirectory = $sameDirectoryUri.TrimEnd($sameDirectoryUriSegments[$sameDirectoryUriSegments.Length - 1]).TrimEnd($sameDirectoryUriSegments[$sameDirectoryUriSegments.Length - 2])
            $differentDirectoryUri = "$($differentDirectory)/XSplit_Broadcaster_$version.exe"
            Invoke-WebRequest -Uri $differentDirectoryUri -Method Head -UserAgent $userAgent | Out-Null
            $returnedUri = $differentDirectoryUri
        }
    }

    return $returnedUri
}

function Get-LatestInternalReleaseInfo($M) {
    $canonicalUri = "https://xspl.it/bc/$M/latest"
    $response = Invoke-WebRequest -Uri $canonicalUri -UserAgent $userAgent -MaximumRedirection 0 -SkipHttpErrorCheck -UseBasicParsing -ErrorAction SilentlyContinue
    
    $redirectedUri = $response.Headers['Location'][0]
    if ($redirectedUri -eq 'https://www.xsplit.com/') {
        throw "$M is not a valid release ID!"
    }
    $version = Get-Version -Version $redirectedUri

    return @{
        ReleaseNotes    = '' #Internal releases are not publicly documented
        SoftwareVersion = $version
        URL64           = Get-OfflineInstallerUri -WebInstallerUri $redirectedUri
        Version         = "$version-internal" #This may change if building a package fix version
    }
}

function Get-LatestPublicReleaseInfo {
    $releaseData = Get-LatestPublicReleaseData
    $version = $releaseData.version

    return @{
        ReleaseNotes    = $releaseData.release_notes_url
        SoftwareVersion = $version
        URL64           = Get-OfflineInstallerUri -WebInstallerUri $releaseData.download_url
        Version         = $version #This may change if building a package fix version
    }
}

function global:au_GetLatest {
    $streams = [ordered] @{
        Stable = Get-LatestPublicReleaseInfo
    }

    $m = 47;
    while ($true) {
        $keyName = "m$m"
        try {
            $streams.Add($keyName, (Get-LatestInternalReleaseInfo -M $keyName))
            $m++
        }
        catch {
            if ($_.Exception.Message -eq "$keyName is not a valid release ID!") {
                #We're done enumerating releases.
                break;
            }
            else {
                #Rethrow original exception
                throw
            }
        }
    }

    return @{ Streams = $streams }
}

$releaseData = Get-LatestPublicReleaseData
$latestPublishedVersion = $releaseData.Version

$currentPath = (Split-Path $MyInvocation.MyCommand.Definition)
$installScriptPath = Join-Path -Path $currentPath -ChildPath 'tools' | Join-Path -ChildPath 'chocolateyInstall.ps1'
$localVersion = (Select-String -Path $installScriptPath -Pattern "(^^\[version\] [$]softwareVersion\s*=\s*)'(.*)'").Matches.Groups[2].Value

if ($latestPublishedVersion -lt $localVersion) {
    Write-Warning "Local version (v$localVersion) is newer than latest published version (v$latestPublishedVersion)"
    Write-Warning "v$localVersion may have been unlisted - skipping URL check due to avoid directory-related errors"

    Update-Package -ChecksumFor None -NoReadme -NoCheckUrl
}
else {
    Update-Package -ChecksumFor None -NoReadme
}
