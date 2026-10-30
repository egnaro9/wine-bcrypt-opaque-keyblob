# Steam on Wine on macOS: an upstream patch and a debugging post-mortem

Notes from a night spent debugging why the Steam client fails on Wine on macOS. This repo is two
things worth keeping:

1. **`wine-patch/`** — a proposed Wine `bcrypt` patch plus a filed WineHQ bug
   ([60214](https://bugs.winehq.org/show_bug.cgi?id=60214)) for a real, independently valid API gap:
   `BCryptExportKey`/`BCryptImportKeyPair` do not implement `BCRYPT_OPAQUE_KEY_BLOB` for asymmetric
   keys (regressed after the post-11.0 PE-crypto rewrite; still missing in master). Status: the gap
   is verified; the patch is **proposed, not yet built or tested** against the tree.

2. **The debugging post-mortem** —
   [Four Wrong Root Causes Before Sunrise](https://dev.to/agentdev9/four-wrong-root-causes-before-sunrise-why-steam-died-on-free-wine-for-macos-and-the-two-2kg2).
   Four confident wrong root causes, and how a working-vs-failing diff found the real signal. Includes
   the correction: I initially over-attributed the Steam login failure to the bcrypt gap, which is
   **not proven**. See the post for the full accounting.

## To actually run Steam on Wine on macOS

Use the maintained path, not the scripts in this repo. Per Gcenx (who maintains the official WineHQ
macOS packages): the official packages plus a small **steamwebhelper wrapper forcing
`--in-process-gpu`** run the **current** Steam client on the MoltenVK renderer. DXMT is a separate,
self-compiled-Wine alternative. Discussion and details:
[Gcenx/macOS_Wine_builds#159](https://github.com/Gcenx/macOS_Wine_builds/issues/159).

## `scripts/` (kept for reference, NOT recommended)

These wrap what I actually ran the night of the post: a GPTk-based Wine (Mythic engine) plus an
**archived early-2025 Steam client** pinned from the Wayback Machine. It works end to end, but it
deliberately uses outdated components and the maintainer reasonably does not recommend running an
outdated third-party Wine against an outdated client. Prefer the maintained path above. The one
durable gotcha if you ever do pin an archived client: verify `logs/bootstrap_log.txt` shows
`steam_client_win32` at a `202503` timestamp, because the Wayback Machine silently redirects the
win64 manifest to a later snapshot that still fails.

Related: [whisky-resurrection](https://github.com/egnaro9/whisky-resurrection) revives the
discontinued Whisky app from its archived runtime (verified, uncontested).

## License

The Wine patch and test in `wine-patch/` are LGPL-2.1-or-later, the same terms as Wine (see
`wine-patch/LICENSE`). Everything else in this repository is copyright Erik Hill, all rights reserved.
