# OpenAL Soft is deployed per game rather than system-wide, so detection is a
# file check in the game directory rather than a registry probe.
#
# Working directory: {InstallDir}\.lancommander\{RedistributableId}\

$Return = (Test-Path (Join-Path $InstallDirectory 'OpenAL32.dll')) -or
          (Test-Path (Join-Path $InstallDirectory 'soft_oal.dll'))
