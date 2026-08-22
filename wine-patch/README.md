> **CORRECTION (2026-08-22):** The bcrypt OpaqueKeyBlob export gap is real and independently
> valid, but it is NOT proven to be what breaks modern Steam login. The macOS Wine package
> maintainer runs the current client with a rendering-only fix (DXMT + a steamwebhelper
> --in-process-gpu wrapper). Treat this as a real bcrypt API-gap report, not a proven Steam
> root cause.

# Upstream Wine fix (bcrypt opaque asymmetric key blob)

The root cause of Steam login failing on Wine > 11.0. Files here:

- `BUGZILLA-REPORT.md` — ready to file at https://bugs.winehq.org (Product: Wine, Component: bcrypt)
- `0001-bcrypt-opaque-asymmetric-key-blob.patch` — the proposed fix against wine 11.15
- `SUGGESTED-TEST.c` — a round-trip test to add to dlls/bcrypt/tests/bcrypt.c

**Submission status: not yet submitted.** Wine does not take GitHub PRs. The real path is:
1. Build wine with this patch, run `make test` in dlls/bcrypt (test suite must pass).
2. File the Bugzilla report; attach the patch.
3. Send the patch via Wine's GitLab (gitlab.winehq.org) merge request or the wine-devel list,
   referencing the bug. Review will likely ask for revisions.

This must be done from a WineHQ account. The patch is PROPOSED (concept proven by binary
transplant, see the report); it needs the build+test pass before it is offered as a real patch.
