# Removes only the files this redistributable deployed. Everything lives inside
# the game's own directory, so there is nothing system-wide to consider.
#
# Working directory: {InstallDir}\.lancommander\{RedistributableId}\Files\

foreach ($file in @('OpenAL32.dll', 'alsoft.ini', 'OpenAL-COPYING.txt')) {
    $path = Join-Path $InstallDirectory $file

    if (Test-Path $path) {
        Remove-Item $path -Force -ErrorAction SilentlyContinue
    }
}

$Return = 0
