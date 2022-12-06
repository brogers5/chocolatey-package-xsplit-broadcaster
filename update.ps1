Import-Module au

function global:au_BeforeUpdate ($Package)  {
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
        'tools\chocolateyInstall.ps1' = @{
            "(^[$]softwareVersion\s*=\s*)'.*'"  = "`$1'$($Latest.Version)'"
            "(^[$]?\s*url64bit\s*=\s*)('.*')"   = "`$1'$($Latest.URL64)'"
            "(^[$]?\s*checksum64\s*=\s*)('.*')" = "`$1'$($Latest.Checksum64)'"
        }
        "$($Latest.PackageName).nuspec" = @{
            "(<packageSourceUrl>)[^<]*(</packageSourceUrl>)" = "`$1https://github.com/brogers5/chocolatey-package-$($Latest.PackageName)/tree/v$($Latest.Version)`$2"
            "(\<releaseNotes\>).*?(\</releaseNotes\>)" = "`${1}$($Latest.ReleaseNotes)`$2"
            "(<copyright>)[^<]*(</copyright>)" = "`$1© $(Get-Date -Format yyyy) SplitmediaLabs, Ltd. All Rights Reserved.`$2"
        }
    }
}

function global:au_GetLatest {
    $uri = 'https://www.xsplit.com/api/service/download?page_size=10&application_id=1&active=1&release=0&platform=windows&installer_type=exe'
    $userAgent = "Update checker of Chocolatey Community Package 'xsplit-broadcaster'"

    $response = Invoke-RestMethod -Uri $uri -UserAgent $userAgent -UseBasicParsing

    $releaseData = $response.data[0]
    $version = $releaseData.version
    $downloadUri = ([System.Uri] $releaseData.download_url)
    $uriSegments = $downloadUri.Segments
    $downloadUrlDirectory = $downloadUri.AbsoluteUri.TrimEnd($uriSegments[$uriSegments.Length - 1]).TrimEnd($uriSegments[$uriSegments.Length - 2])

    return @{
        URL64 = "$($downloadUrlDirectory)/XSplit_Broadcaster_$version.exe"
        Version = $version
        ReleaseNotes = $releaseData.release_notes_url
    }
}

Update-Package -ChecksumFor None -NoReadme
