# Steam on free Wine on macOS (2026)

> **Correction (2026-08-22):** An earlier version of this repo claimed the missing bcrypt
> OpaqueKeyBlob export was *the* cause of modern Steam login failure, and that only Apple's
> D3DMetal could solve rendering. Both are corrected. The bcrypt gap is real but NOT proven to
> be the login-blocker; Gcenx (maintainer of the macOS Wine packages) runs the *current* Steam
> client with a rendering fix alone: a steamwebhelper wrapper forcing `--in-process-gpu` so DXMT
> works. The free recipe below is still verified end to end.


Steam login and Steam-DRM games working on a fully free Wine stack on Apple Silicon, with the
root-cause diagnosis of why stock Wine cannot do it. Verified end to end on 2026-08-22 (macOS,
M4): client login via QR, then a Steam-DRM game (The Wolf Among Us) running.

**TL;DR recipe**

1. A GPTk-based Wine (free, includes Apple's D3DMetal). This setup used Mythic Engine, whose
   manifest lists the current tarball: `https://dl.getmythic.app/engine/EngineUpdateStream.plist`
2. Fresh prefix, install Steam with a stock `SteamSetup.exe` silently.
3. Pin the archived early-2025 client BEFORE the first normal launch (one unpinned boot
   self-updates past the last Wine-compatible client):
   ```
   wine64 Steam.exe -forcesteamupdate -forcepackagedownload \
     -overridepackageurl http://web.archive.org/web/20250311093241if_/media.steampowered.com/client \
     -exitsteam
   ```
   Then verify `logs/bootstrap_log.txt` shows `steam_client_win32` at a `202503` timestamp
   (client build 1737514353). The Wayback Machine silently redirects the win64 manifest to a
   Dec 2025 snapshot that still fails; the win32 manifest at this timestamp is the working one.
4. Always launch frozen:
   ```
   wine64 Steam.exe -noverifyfiles -nobootstrapupdate -norepairfiles \
     -overridepackageurl <same URL>
   ```
5. Optional, to avoid re-downloading games: pull once with SteamCMD
   (`+@sSteamCmdForcePlatformType windows`), then symlink into `C:\SteamLibrary\steamapps\common\`
   plus copy the appmanifest and register the library in `libraryfolders.vdf`.

Never run two Steam clients at once (native macOS Steam included): the second client's
networking fails completely and looks like a broken install.

The `scripts/` folder wraps these steps. The commands are verbatim from the verified session;
the wrapper scripts themselves are convenience.

**Why stock Wine fails** (short version; full diagnosis in `docs/diagnosis.md`):

- Auth: upstream Wine dropped its gnutls-backed CNG unixlib after 11.6. Steam's device-key auth
  calls `BCryptExportKey(BCRYPT_OPAQUE_KEY_BLOB)` on an asymmetric key, gets
  STATUS_NOT_IMPLEMENTED, and every auth session (QR included) dies locally while the client's
  own connection looks healthy. Still unimplemented in Wine master as of Aug 2026.
- Rendering: Steam's CEF wants a GLES 3.0 context; ANGLE's D3D11 renderer on wined3d-on-GL caps
  at 2.0 (black window). DXMT does not rescue CEF: cross-process swapchains are unsupported.
  Apple's D3DMetal handles both, which is why GPTk-based Wine (and CrossOver) render.

Related: the same client pin revives Whisky, whose repo is archived; see
[whisky-resurrection](https://github.com/egnaro9/whisky-resurrection).
Posted as a comment on Gcenx/macOS_Wine_builds#159, and filed upstream as
WineHQ bug 60214: https://bugs.winehq.org/show_bug.cgi?id=60214
