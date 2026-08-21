# LANCommander.Redistributables.OpenALSoft

Automatically built LANCommander redistributable import package (`.LCX`) for
[OpenAL Soft](https://openal-soft.org/).

OpenAL Soft is a software implementation of the OpenAL 3D audio API. It is a
drop-in replacement for the original Creative OpenAL runtime, which a great many
early-2000s titles require and which no longer installs cleanly on modern
Windows. Installing it per game is usually enough to bring sound back.

## Install it

Download `redistributable.lcx` from the [latest release][latest] and import it
through your LANCommander server's **Redistributables** page, or from the CLI:

```
LANCommander.Launcher.CLI Import --Path redistributable.lcx --Type Redistributable
```

Then assign it to the games that need it, from either the game's
**Redistributables** field or this redistributable's **Games** field.

Re-importing a newer release **updates** the existing entry rather than creating a
second one, because the identifiers in `redistributable.yml` are stable across
releases. You can also import once and leave it alone: the package ships a
`Package` script that a LANCommander server runs on a schedule to pull new
versions straight from this repository's releases.

[latest]: https://github.com/LANCommander/LANCommander.Redistributables.OpenALSoft/releases/latest

## What it installs

The runtime is deployed **into the game's own directory**, not into System32.
Replacing the system-wide OpenAL would affect every application on the machine,
which is both riskier and broader than a per-game redistributable should be.

| File | |
|---|---|
| `OpenAL32.dll` | The runtime, which upstream ships as `soft_oal.dll` |
| `alsoft.ini` | The default configuration, written from the option schema |
| `OpenAL-COPYING.txt` | The upstream LGPL text |

The Install script reads the PE header of the game's primary executable and
deploys the matching 32- or 64-bit build. A mismatched DLL does not error — it
simply fails to load, and the game falls back to silence.

## Options

The schema is generated from OpenAL Soft's own `alsoftrc.sample`, so it covers
every documented option — 89 of them across 12 groups — and picks up new ones
automatically as upstream adds them.

| Group | |
|---|---|
| `Output` | Channel configuration, sample type, sample rate, stereo mode and encoding |
| `Hrtf` | Head-related transfer function, for positional audio over headphones |
| `Performance` | Buffer sizing, resampler, source and slot limits |
| `General` | Everything else global, including crossfeed and backend order |
| `Decoder` | Ambisonic decoder configuration |
| `Uhj`, `Tsme` | Stereo-compatible surround encoding |
| `Reverb`, `Eax` | Environmental audio extensions |
| `Wasapi`, `Wave` | Windows backend tuning and wave-file output |
| `Game_compat` | Per-title compatibility quirks |

Linux and BSD backend groups (PipeWire, PulseAudio, ALSA, OSS, Solaris, JACK,
PortAudio) are excluded — 26 options a Windows game will never reach.

Administrators can override any option per game from the game's
**Redistributables** page. Values resolve as schema default, then per-game value,
then per-action override.

## How this repository works

| File | Purpose |
|---|---|
| `redistributable.yml` | Identity, payload source, config paths, stable script GUIDs |
| `source.ps1` | Downloads the upstream release and the matching `alsoftrc.sample` |
| `Schema.Overlay.yml` | Hand-written curation: names, descriptions, choices, grouping |
| `OptionSchema.yml` | Generated from `alsoft.ini`, then curated. Do not edit by hand |
| `Scripts/*.ps1` | DetectInstall, Install, Uninstall and the server-side Package updater |

`OptionSchema.yml` is generated, and the build fails if the committed copy does
not match what the upstream config produces. To regenerate it locally:

```powershell
Import-Module <hub>/module/LANCommander.Redistributables
Invoke-RedistributableBuild -RepositoryPath . -UpdateSchema
```

Edit `Schema.Overlay.yml` to change how an option is presented; never edit
`OptionSchema.yml`, since the next rebuild overwrites it.

### Staying current

A scheduled workflow watches [kcat/openal-soft][upstream] for new releases. When
one appears it downloads the new `alsoftrc.sample`, regenerates the option schema
through the overlay, and opens a pull request listing exactly which options were
added, removed, or had their defaults change. Merging it publishes the release.

Because the parser enumerates whatever keys the sample config contains, an option
OpenAL Soft adds is picked up with no change to any script here. It ships with the
description upstream wrote for it, and the pull request flags it so a friendlier
name can be added if it needs one.

[upstream]: https://github.com/kcat/openal-soft

## Licensing

The scripts and workflows here are MIT licensed. OpenAL Soft itself is LGPL v2 and
is not ours — see [`LICENSES/NOTICE.md`](LICENSES/NOTICE.md) for attribution, the
obligations we carry, and where to obtain the corresponding source.
