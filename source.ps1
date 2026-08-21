<#
.SYNOPSIS
    Resolves and downloads the upstream OpenAL Soft release.
.DESCRIPTION
    Contract:
      -CheckOnly            write the upstream version to stdout and exit.
      -OutputPath <dir>     download and extract the payload there, then emit a
                            JSON object with Version and optionally Changelog.

    The published binary archive carries headers, import libraries, HRTF data and
    a configuration GUI -- none of which belong next to a game executable. Only
    the runtime DLLs are packaged.

    alsoftrc.sample is fetched separately from the source tree at the same tag and
    written as alsoft.ini, which is the filename OpenAL Soft reads. It is both the
    shipped default configuration and the file the option schema is generated
    from, so the schema always describes the exact version being packaged.
#>
[CmdletBinding(DefaultParameterSetName = 'Download')]
param(
    [Parameter(ParameterSetName = 'Check')][switch] $CheckOnly,
    [Parameter(ParameterSetName = 'Download', Mandatory)][string] $OutputPath
)

$ErrorActionPreference = 'Stop'

$definition = Get-RedistributableDefinition -Path $PSScriptRoot
$source = $definition['Source']

$upstream = Resolve-UpstreamVersion -Resolver ([string] $source['Resolver']) `
    -Url ([string] $source['Url']) `
    -AssetPattern ([string] $source['AssetPattern'])

if ($CheckOnly) {
    Write-Output $upstream.Version
    return
}

if (-not $upstream.DownloadUrl) {
    throw "No asset matched '$($source['AssetPattern'])' on the latest release"
}

$temp = Join-Path ([System.IO.Path]::GetTempPath()) "openalsoft-$([guid]::NewGuid())"
$archive = Join-Path $temp 'bin.zip'
$extracted = Join-Path $temp 'extracted'

$null = New-Item -ItemType Directory -Path $temp -Force

try {
    Write-Verbose "Downloading $($upstream.DownloadUrl)"
    Invoke-WebRequest -Uri $upstream.DownloadUrl -OutFile $archive -MaximumRetryCount 3 -RetryIntervalSec 5

    Expand-Archive -Path $archive -DestinationPath $extracted -Force

    # The archive nests everything under openal-soft-<version>-bin/.
    $root = Get-ChildItem -LiteralPath $extracted -Directory | Select-Object -First 1
    if (-not $root) { throw 'The downloaded archive did not contain the expected directory' }

    # Both architectures ship; the Install script picks per game executable.
    foreach ($architecture in @('Win32', 'Win64')) {
        $dll = Join-Path $root.FullName "bin/$architecture/soft_oal.dll"

        if (-not (Test-Path -LiteralPath $dll)) {
            throw "Expected bin/$architecture/soft_oal.dll in the upstream archive"
        }

        $destination = Join-Path $OutputPath $architecture
        $null = New-Item -ItemType Directory -Path $destination -Force
        Copy-Item -LiteralPath $dll -Destination $destination -Force
    }

    # The documented option set, at the exact tag being packaged.
    $sampleUri = "https://raw.githubusercontent.com/kcat/openal-soft/$($upstream.Version)/alsoftrc.sample"
    Invoke-WebRequest -Uri $sampleUri -OutFile (Join-Path $OutputPath 'alsoft.ini') -MaximumRetryCount 3 -RetryIntervalSec 5

    # LGPL: the licence has to travel with the binaries.
    $license = Join-Path $PSScriptRoot 'LICENSES/UPSTREAM-LICENSE.txt'
    if (Test-Path -LiteralPath $license) {
        Copy-Item -LiteralPath $license -Destination (Join-Path $OutputPath 'COPYING.txt') -Force
    }

    @{
        Version   = $upstream.Version
        Changelog = $upstream.Changelog
    } | ConvertTo-Json -Compress | Write-Output
}
finally {
    Remove-Item -LiteralPath $temp -Recurse -Force -ErrorAction SilentlyContinue
}
