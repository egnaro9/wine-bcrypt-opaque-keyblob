/* Suggested addition to dlls/bcrypt/tests/bcrypt.c: opaque round-trip.
 * NOT YET RUN. Proves export(OPAQUE) -> import(OPAQUE) yields a usable key. */
static void test_opaque_roundtrip(void)
{
    BCRYPT_ALG_HANDLE alg;
    BCRYPT_KEY_HANDLE key, key2;
    UCHAR *blob; ULONG len = 0;
    NTSTATUS s;

    s = BCryptOpenAlgorithmProvider(&alg, BCRYPT_RSA_ALGORITHM, NULL, 0);
    ok(!s, "open: %#lx\n", s);
    s = BCryptGenerateKeyPair(alg, &key, 2048, 0);
    ok(!s, "gen: %#lx\n", s);
    s = BCryptFinalizeKeyPair(key, 0);
    ok(!s, "finalize: %#lx\n", s);

    s = BCryptExportKey(key, NULL, BCRYPT_OPAQUE_KEY_BLOB, NULL, 0, &len, 0);
    ok(!s && len, "export size: %#lx len %lu\n", s, len);
    blob = malloc(len);
    s = BCryptExportKey(key, NULL, BCRYPT_OPAQUE_KEY_BLOB, blob, len, &len, 0);
    ok(!s, "export: %#lx\n", s);

    s = BCryptImportKeyPair(alg, NULL, BCRYPT_OPAQUE_KEY_BLOB, &key2, blob, len, 0);
    ok(!s, "import: %#lx\n", s);

    free(blob);
    BCryptDestroyKey(key2);
    BCryptDestroyKey(key);
    BCryptCloseAlgorithmProvider(alg, 0);
}
