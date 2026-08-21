# Deploys the OpenAL Soft runtime beside the game executable.
#
# No elevation: this writes into the game's own install directory, not System32.
# Replacing the system OpenAL would affect every application on the machine,
# which is both riskier and outside what a per-game redistributable should do.
#
# Working directory: {InstallDir}\.lancommander\{RedistributableId}\Files\
# -- containing Win32\, Win64\, alsoft.ini and COPYING.txt.

# Match the architecture of the game's primary executable. A 64-bit DLL beside a
# 32-bit game silently fails to load and the game falls back to no sound.
$executable = $GameManifest.Actions |
    Where-Object { $_.IsPrimaryAction } |
    Select-Object -First 1 -ExpandProperty Path

if ($executable) {
    $executable = $executable.Replace('{InstallDir}', $InstallDirectory)
}

$architecture = 'Win32'

if ($executable -and (Test-Path $executable)) {
    try {
        $kind = [System.Reflection.AssemblyName]::GetAssemblyName($executable).ProcessorArchitecture
        if ($kind -eq 'Amd64') { $architecture = 'Win64' }
    }
    catch {
        # Native executables are not assemblies, so read the PE header directly.
        $stream = [System.IO.File]::OpenRead($executable)

        try {
            $reader = [System.IO.BinaryReader]::new($stream)
            $stream.Position = 0x3C
            $peOffset = $reader.ReadInt32()
            $stream.Position = $peOffset + 4
            $machine = $reader.ReadUInt16()

            # 0x8664 = x64, 0x014C = x86
            if ($machine -eq 0x8664) { $architecture = 'Win64' }
        }
        finally {
            $stream.Dispose()
        }
    }
}

Write-Host "Deploying OpenAL Soft ($architecture) to $InstallDirectory"

# Games load the runtime as OpenAL32.dll; upstream ships it as soft_oal.dll.
Copy-Item -Path (Join-Path $architecture 'soft_oal.dll') -Destination (Join-Path $InstallDirectory 'OpenAL32.dll') -Force

# The default configuration and the LGPL text ship alongside it.
Copy-Item -Path 'alsoft.ini' -Destination $InstallDirectory -Force
Copy-Item -Path 'COPYING.txt' -Destination (Join-Path $InstallDirectory 'OpenAL-COPYING.txt') -Force

$Return = 0
