Root-caused this, with a working free path at the end. Evidence from a night of differential testing between wine-staging 11.15 (fails), Gcenx 11.6_1 (auth works), and CrossOver 26 (works fully).

## Why login broke after 11.6

The post-11.6 packages are pure upstream, and upstream wine dropped the gnutls-backed CNG unixlib (`bcrypt.so`) in the PE-crypto rewrite. Steam's device-key auth needs `BCryptExportKey` with `BCRYPT_OPAQUE_KEY_BLOB` on an asymmetric key. On 11.15 that path returns STATUS_NOT_IMPLEMENTED:

```
fixme:bcrypt:export_asymmetric_key unsupported blob type L"OpaqueKeyBlob"
fixme:ncrypt:map_ntstatus unhandled status 0xc0000002
```

After that, every auth session fails locally before touching the network. QR generation included, which is why the login page just polls forever (`Login: Failed to poll auth session. Result 2. Transport Error: 2` in cef_log). The client's own CM WebSocket connects fine the whole time, which is what makes this so misleading.

Checked upstream master (Aug 2026): `export_asymmetric_key` in `dlls/bcrypt/bcrypt_main.c` still has no OpaqueKeyBlob branch, so no current or future stock build fixes this without a patch. CrossOver 26 works because it is wine 11.0 (its bcrypt/ncrypt are byte-identical to upstream 11.0, verified against the LGPL source tarball), i.e. the gnutls-unixlib era.

Verification: transplanting the wine-11.0 bcrypt/ncrypt PE pair plus `bcrypt.so` into 11.15 staging removed both fixmes and Steam progressed to QR generation.

## The second, independent wall: rendering

Steam's CEF requests a GLES 3.0 context. ANGLE's D3D11 renderer on wined3d-on-GL caps out at 2.0:

```
eglCreateContext: Requested GLES version (3.0) is greater than max supported (2, 0)
```

DXMT does not rescue this: its dxgi reports `CreateSwapChain: cross-process swapchain not supported yet` for CEF's out-of-process GPU. D3DMetal handles it, which is the other half of why CrossOver works.

## Working free setup today (verified end to end, game running)

GPTk-based wine (free, Apple D3DMetal included) plus the archived early-2025 Steam client:

1. Mythic Engine (Whisky's lineage): manifest at `https://dl.getmythic.app/engine/EngineUpdateStream.plist`, current stable tarball linked inside. Extract anywhere.
2. Fresh prefix, install SteamSetup.exe.
3. Before any unpinned launch, pin the client:
   ```
   wine64 Steam.exe -forcesteamupdate -forcepackagedownload -overridepackageurl http://web.archive.org/web/20250311093241if_/media.steampowered.com/client -exitsteam
   ```
   Trap: one unpinned boot self-updates to the current client, which requests `steam_client_win64`. The Wayback Machine has no 2025 snapshot of that file and silently redirects to Dec 2025, which still fails. The URL above resolves the win32 manifest, which is archived at that timestamp (installs client build 1737514353).
4. Always launch with `-noverifyfiles -nobootstrapupdate -norepairfiles -overridepackageurl <same URL>`.

QR/mobile login works on that client (it predates the CNG device-key flow). Verified through to a Steam-DRM game running.

Happy to file the bcrypt gap on winehq bugzilla with the full logs if useful; an OpaqueKeyBlob asymmetric export/import in bcrypt_main.c looks like a contained patch since the blob only needs to round-trip within the same implementation.
