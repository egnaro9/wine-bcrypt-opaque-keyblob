# WineHQ Bugzilla report (ready to file)

**Product:** Wine  **Component:** bcrypt  **Version:** 11.15 (present since the post-11.0 PE-crypto rewrite; still in master 2026-08)
**Summary:** bcrypt: BCryptExportKey/BCryptImportKeyPair do not support BCRYPT_OPAQUE_KEY_BLOB for asymmetric keys, breaking modern Steam login

## Description

The modern Steam client's device-key login exports an asymmetric key with
`BCryptExportKey(key, NULL, BCRYPT_OPAQUE_KEY_BLOB, ...)`. Wine's
`export_asymmetric_key()` in `dlls/bcrypt/bcrypt_main.c` has no branch for
`BCRYPT_OPAQUE_KEY_BLOB` and returns STATUS_NOT_IMPLEMENTED:

```
fixme:bcrypt:export_asymmetric_key unsupported blob type L"OpaqueKeyBlob"
fixme:ncrypt:map_ntstatus unhandled status 0xc0000002
```

Because this fails locally, every Steam auth session dies before any network
traffic (QR generation included). In the client's CEF log this surfaces as:

```
Login: Failed to poll auth session. Result 2. Transport Error: 2
```

while the client's own CM WebSocket connects normally, which makes the failure
look like a networking bug when it is not.

## Regression

`BCRYPT_OPAQUE_KEY_BLOB` was supported by the older gnutls-backed bcrypt
(originally added for Titanfall 2, ~2018). The post-11.0 rewrite to the
PE/SymCrypt bcrypt did not carry opaque asymmetric export/import forward.

## How reproducible: always (Steam login on Wine, macOS or Linux, wine > 11.0)

## Evidence it is the cause (not just correlated)

Differential test across three stacks on macOS/M4, 2026-08-22:

| signal (cef/wine logs) | wine 11.15 (fails) | wine 11.6 (works) | CrossOver 26 = wine 11.0 (works) |
|---|---|---|---|
| `export_asymmetric_key ... OpaqueKeyBlob` fixme | present | absent | absent |
| `Failed to poll auth session` | continuous | absent | absent |
| reaches QR / logs on | no | yes | yes |

Transplanting the wine-11.0 `bcrypt.dll`/`ncrypt.dll` PE pair plus `bcrypt.so`
into an 11.15 prefix removed the fixme and Steam progressed to QR generation.
CrossOver's bcrypt/ncrypt are byte-identical to upstream wine-11.0 (verified
against the published CrossOver 26 LGPL source tarball); CrossOver applies no
patch to bcrypt/ncrypt at all. So the difference is purely the dropped opaque
support, nothing CrossOver-proprietary.

## Proposed fix

Attached: `0001-bcrypt-opaque-asymmetric-key-blob.patch`. Opaque blobs are
implementation-private by contract (importable only into the same provider),
so the patch serializes the fullest standard blob for the key with an 8-byte
tag header, and import reverses it. Both directions reuse the existing per-alg
export/import helpers.

**Status: PROPOSED, not yet built or run against this tree.** The approach is
proven by the binary transplant above; this specific reimplementation needs a
wine build + the bcrypt test suite before it is submitted as a real patch. A
suggested round-trip test is in `SUGGESTED-TEST.c`.
