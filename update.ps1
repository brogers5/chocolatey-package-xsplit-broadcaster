Import-Module au

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
            "(^[$]softwareVersion\s*=\s*)'.*'"  = "`$1'$($Latest.SoftwareVersion)'"
            "(^[$]?\s*url64bit\s*=\s*)('.*')"   = "`$1'$($Latest.URL64)'"
            "(^[$]?\s*checksum64\s*=\s*)('.*')" = "`$1'$($Latest.Checksum64)'"
        }
        "$($Latest.PackageName).nuspec" = @{
            "(<packageSourceUrl>)[^<]*(</packageSourceUrl>)" = "`$1https://github.com/brogers5/chocolatey-package-$($Latest.PackageName)/tree/v$($Latest.Version)`$2"
            "(\<releaseNotes\>).*?(\</releaseNotes\>)"       = "`${1}$($Latest.ReleaseNotes)`$2"
            "(<copyright>)[^<]*(</copyright>)"               = "`$1© $(Get-Date -Format yyyy) SplitmediaLabs, Ltd. All Rights Reserved.`$2"
        }
    }
}

function Get-LatestReleaseData {
    $uri = 'https://www.xsplit.com/api/service/download?page_size=10&application_id=1&active=1&release=0&platform=windows&installer_type=exe'
    $userAgent = "Update checker of Chocolatey Community Package 'xsplit-broadcaster'"

    $response = Invoke-RestMethod -Uri $uri -UserAgent $userAgent -UseBasicParsing

    return $response.data[0]
}

function global:au_GetLatest {
    $releaseData = Get-LatestReleaseData
    $version = $releaseData.version

    #The package uses the offline installer, but SplitMediaLabs only publishes the web installer's URI.
    #This is only publicly shared via the web installer, and exposed as an alternate location in the installer.
    #We may need to cross-check against it or probe the server every now and then to keep up with changes.
    $webInstallerUri = ([System.Uri] $releaseData.download_url)
    $webInstallerUriSegments = $webInstallerUri.Segments
    $downloadUrlDirectory = $webInstallerUri.AbsoluteUri.TrimEnd($webInstallerUriSegments[$webInstallerUriSegments.Length - 1])

    return @{
        ReleaseNotes    = $releaseData.release_notes_url
        SoftwareVersion = $version
        URL64           = "$($downloadUrlDirectory)XSplit_Broadcaster_$version.exe"
        Version         = $version #This may change if building a package fix version
    }
}

$releaseData = Get-LatestReleaseData
$latestPublishedVersion = $releaseData.Version

$currentPath = (Split-Path $MyInvocation.MyCommand.Definition)
$installScriptPath = Join-Path -Path $currentPath -ChildPath 'tools' | Join-Path -ChildPath 'chocolateyInstall.ps1'
$localVersion = (Select-String -Path $installScriptPath -Pattern "(^[$]softwareVersion\s*=\s*)'(.*)'").Matches.Groups[2].Value

if ($latestPublishedVersion -lt $localVersion) {
    Write-Warning "Local version (v$localVersion) is newer than latest published version (v$latestPublishedVersion)"
    Write-Warning "v$localVersion may have been unlisted - skipping URL check due to avoid directory-related errors"

    Update-Package -ChecksumFor None -NoReadme -NoCheckUrl
}
else {
    Update-Package -ChecksumFor None -NoReadme
}
