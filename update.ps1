[CmdletBinding()]
param($IncludeStream)
Import-Module au

$userAgent = "Update checker of Chocolatey Community Package 'xsplit-broadcaster'"

function global:au_BeforeUpdate ($Package) {
    $streamName = $Latest.Stream
    $stableVersion = [version] $Package.Streams['Stable']['NuspecVersion']
    if ($streamName -ne 'Stable' -and $Latest.SoftwareVersion.Version -eq $stableVersion) {
        throw "Latest $($Latest.Stream) build now points to the latest Stable build, but does not need a new package!"
    }

    #Archive this version for future development, since the vendor does not guarantee perpetual availability
    $filePath = ".\XSplit_Broadcaster_$($Latest.Version).exe"
    Invoke-WebRequest -Uri $Latest.URL64 -OutFile $filePath
    $Latest.Checksum64 = (Get-FileHash -Path $filePath -Algorithm SHA256).Hash.ToLower()

    if ((Get-Command -Name 'vt' -CommandType Application -ErrorAction SilentlyContinue)) {
        vt.exe scan file "$filePath" --silent
    }
    else {
        Write-Warning 'VirusTotal CLI is not available - skipping VirusTotal submission'
    }

    $readmePath = '.\DESCRIPTION.md'
    $readmeContents = Get-Content $readmePath -Encoding UTF8
    $readmeContents = $readmeContents -replace '/blob/v.*\/', "/blob/v$($Latest.Version)/"

    $encoding = New-Object System.Text.UTF8Encoding($false)
    $output = $readmeContents | Out-String
    [System.IO.File]::WriteAllText((Get-Item $readmePath).FullName, $output, $encoding)

    Set-DescriptionFromReadme -Package $Package -ReadmePath $readmePath
}

function global:au_SearchReplace {
    @{
        'tools\chocolateyInstall.ps1'   = @{
            '(^\[version\] [$]softwareVersion\s*=\s*)(''.*'')' = "`$1'$($Latest.SoftwareVersion)'"
            "(^[$]?\s*url64bit\s*=\s*)('.*')"                  = "`$1'$($Latest.URL64)'"
            "(^[$]?\s*checksum64\s*=\s*)('.*')"                = "`$1'$($Latest.Checksum64)'"
        }
        "$($Latest.PackageName).nuspec" = @{
            '(<packageSourceUrl>)[^<]*(</packageSourceUrl>)' = "`$1https://github.com/brogers5/chocolatey-package-$($Latest.PackageName)/tree/v$($Latest.Version)`$2"
            '(\<releaseNotes\>).*?(\</releaseNotes\>)'       = "`${1}$($Latest.ReleaseNotes)`$2"
            '(<copyright>)[^<]*(</copyright>)'               = "`$1© $(Get-Date -Format yyyy) SplitmediaLabs, Ltd. All Rights Reserved.`$2"
        }
    }
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
        else {
            #Rethrow original exception
            throw
        }
    }

    return $returnedUri
}

function Get-LatestVersionResponse([string] $Uri) {
    return Invoke-WebRequest -Uri $Uri -UserAgent $userAgent -MaximumRedirection 0 -SkipHttpErrorCheck -UseBasicParsing -ErrorAction SilentlyContinue
}

function Get-ReleaseDataFromUriResponse($Response) {
    $redirectedUri = $Response.Headers['Location'][0]
    
    return @{
        RedirectedUri = $redirectedUri
        Version       = Get-Version -Version $redirectedUri
    }
}

function Get-LatestInternalReleaseInfo($M) {
    $response = Get-LatestVersionResponse -Uri "https://xspl.it/bc/$M/latest"
    if ($response.StatusCode -eq [System.Net.HttpStatusCode]::NotFound) {
        throw "$M is not a valid release ID!"
    }
    
    $releaseData = Get-ReleaseDataFromUriResponse -Response $response

    return @{
        ReleaseNotes    = '' #Internal releases are not publicly documented
        SoftwareVersion = $releaseData.Version
        URL64           = Get-OfflineInstallerUri -WebInstallerUri $releaseData.RedirectedUri
        Version         = "$($releaseData.Version)-internal" #This may change if building a package fix version
    }
}

function Get-LatestBetaReleaseInfo {
    $response = Get-LatestVersionResponse -Uri 'https://xspl.it/bc/beta'
    $releaseData = Get-ReleaseDataFromUriResponse -Response $response

    return @{
        ReleaseNotes    = '' #Beta releases are not publicly documented
        SoftwareVersion = $releaseData.Version
        URL64           = $releaseData.RedirectedUri
        Version         = "$($releaseData.Version)-beta" #This may change if building a package fix version
    }
}

function Get-LatestPublicReleaseInfo {
    $response = Get-LatestVersionResponse -Uri 'https://xspl.it/download'
    $releaseData = Get-ReleaseDataFromUriResponse -Response $response

    return @{
        ReleaseNotes    = "https://xspl.it/bc/relnotes/$($releaseData.Version)"
        SoftwareVersion = $releaseData.Version
        URL64           = $releaseData.RedirectedUri
        Version         = $releaseData.Version #This may change if building a package fix version
    }
}

function global:au_GetLatest {
    $streams = [ordered] @{}

    $m = 47
    while ($true) {
        $keyName = "m$m"
        try {
            $streams.Add($keyName, (Get-LatestInternalReleaseInfo -M $keyName))
            $m++
        }
        catch {
            if ($_.Exception.Message -eq "$keyName is not a valid release ID!") {
                #We're done enumerating releases.
                break
            }
            else {
                #Rethrow original exception
                throw
            }
        }
    }

    $streams.Add('Beta', (Get-LatestBetaReleaseInfo))
    $streams.Add('Stable', (Get-LatestPublicReleaseInfo))

    return @{ Streams = $streams }
}

try {
    Update-Package -ChecksumFor None -IncludeStream $IncludeStream -NoReadme
}
catch {
    $ignore = 'build now points to the latest Stable build, but does not need a new package!'
    if ($_ -match $ignore) {
        $streamVersionsFilePath = ".\$($Latest.PackageName).json"

        #Silently update this stream's version, so we can effectively ignore it going forward
        $streams = Get-Content -Path $streamVersionsFilePath -Raw | ConvertFrom-Json
        $currentStreamName = $Latest.Stream
        $streams.$($currentStreamName) = $Latest.Version
        $streams | ConvertTo-Json | Set-Content -Path $streamVersionsFilePath

        Write-Warning $_ ; 'ignore'
    }
    else { 
        throw $_
    }
}
