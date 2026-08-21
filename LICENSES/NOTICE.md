# Attribution and licensing

This repository contains two separately licensed things. Keeping them distinct
matters, because only one of them is ours to license.

## What we authored

The packaging scripts, workflows, option schema, curation overlay and
documentation in this repository are copyright (c) 2026 LANCommander and are
released under the MIT License, in `LICENSE`.

## What we redistribute

The published `.LCX` package contains binaries from **OpenAL Soft**, which we did
not author and do not license. Those files remain under their own terms:

| | |
|---|---|
| Project | OpenAL Soft |
| Homepage | https://openal-soft.org/ |
| Source | https://github.com/kcat/openal-soft |
| Copyright | (c) the OpenAL Soft contributors |
| License | GNU Library General Public License, version 2 |

The full upstream licence is in `UPSTREAM-LICENSE.txt` and is also packed inside
the payload archive as `COPYING.txt`, so it travels with the binaries rather than
only living here. The Install script deploys it into the game directory alongside
the runtime.

### Obligations we carry

- The licence text ships with the binaries, in the package and on disk after install.
- The corresponding source for the exact build packaged here is the upstream
  release it was downloaded from. Each of our releases records the upstream
  version, and the matching source is at
  `https://github.com/kcat/openal-soft/releases/tag/<version>`.
- The runtime is shipped unmodified, as a dynamically loaded library that a user
  can replace with their own build by overwriting `OpenAL32.dll` in the game
  directory. Nothing is statically linked and nothing is patched.

### Why this payload is distributed the way it is

The LGPL permits redistributing the unmodified library provided the licence
travels with it and users can substitute their own build. Both hold here, so the
binaries are bundled into the package rather than downloaded on the client.

---

If you are a copyright holder for OpenAL Soft and would prefer this package not
redistribute your files, please open an issue and we will switch it to downloading
from you directly at install time.
