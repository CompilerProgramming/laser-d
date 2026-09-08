import core.stdc.stdlib : EXIT_FAILURE, EXIT_SUCCESS;
import laserd.memory : Arena, Arena_create_fixedregion, Arena_create_rpmalloc,
    Arena_destroy;
import laserd.utf8proc;

private bool bytesEqual(const(char)[] actual, const(ubyte)[] expected)
{
    if (actual.length != expected.length)
        return false;
    foreach (index, value; expected)
        if (cast(ubyte) actual[index] != value)
            return false;
    return true;
}

private int testNativeApi()
{
    ubyte[4] smile = [0xF0, 0x9F, 0x99, 0x82];
    int codepoint;
    if (utf8proc_iterate(smile.ptr, smile.length, &codepoint) != 4
        || codepoint != 0x1F642)
        return EXIT_FAILURE;
    ubyte[4] encoded;
    if (utf8proc_encode_char(codepoint, encoded.ptr) != 4)
        return EXIT_FAILURE;
    foreach (index, value; smile)
        if (encoded[index] != value)
            return EXIT_FAILURE;

    ubyte[2] invalid = [0xC0, 0x80];
    if (utf8proc_iterate(invalid.ptr, invalid.length, &codepoint)
        != UTF8PROC_ERROR_INVALIDUTF8)
        return EXIT_FAILURE;
    if (!utf8proc_codepoint_valid(0x10FFFF)
        || utf8proc_codepoint_valid(0xD800))
        return EXIT_FAILURE;
    if (utf8proc_category('A') != UTF8PROC_CATEGORY_LU
        || utf8proc_category(0x03B4) != UTF8PROC_CATEGORY_LL)
        return EXIT_FAILURE;
    if (utf8proc_toupper(0x03B4) != 0x0394
        || utf8proc_tolower(0x0416) != 0x0436)
        return EXIT_FAILURE;
    int state;
    if (utf8proc_grapheme_break_stateful('a', 0x0308, &state))
        return EXIT_FAILURE;
    return EXIT_SUCCESS;
}

private int testArenaTransforms(Arena* arena)
{
    char[3] decomposed = ['a', cast(char) 0xCC, cast(char) 0x88];
    Utf8procBuffer nfc = utf8proc_transform(
        arena, decomposed[], UTF8PROC_STABLE | UTF8PROC_COMPOSE);
    ubyte[2] expectedNfc = [0xC3, 0xA4];
    if (!nfc.ok() || !bytesEqual(nfc.data, expectedNfc[]))
        return EXIT_FAILURE;
    utf8proc_buffer_destroy(nfc);

    char[2] sharpS = [cast(char) 0xC3, cast(char) 0x9F];
    Utf8procBuffer folded = utf8proc_transform(
        arena, sharpS[], UTF8PROC_STABLE | UTF8PROC_COMPOSE
            | UTF8PROC_CASEFOLD);
    ubyte[2] expectedFolded = ['s', 's'];
    if (!folded.ok() || !bytesEqual(folded.data, expectedFolded[]))
        return EXIT_FAILURE;
    utf8proc_buffer_destroy(folded);

    char[2] invalid = [cast(char) 0xC0, cast(char) 0x80];
    Utf8procBuffer rejected = utf8proc_transform(
        arena, invalid[], UTF8PROC_STABLE | UTF8PROC_COMPOSE);
    if (rejected.error != UTF8PROC_ERROR_INVALIDUTF8
        || rejected.allocation !is null)
        return EXIT_FAILURE;
    return EXIT_SUCCESS;
}

private int testAllocationFailure()
{
    Arena* arena = Arena_create_fixedregion(1);
    if (arena is null)
        return EXIT_FAILURE;
    char[3] input = ['a', cast(char) 0xCC, cast(char) 0x88];
    Utf8procBuffer result = utf8proc_transform(
        arena, input[], UTF8PROC_STABLE | UTF8PROC_COMPOSE);
    int status = result.error == UTF8PROC_ERROR_NOMEM
        && result.allocation is null ? EXIT_SUCCESS : EXIT_FAILURE;
    Arena_destroy(arena);
    return status;
}

extern(C) int main()
{
    int result = testNativeApi();
    if (result != EXIT_SUCCESS)
        return result;
    Arena* arena = Arena_create_rpmalloc();
    if (arena is null)
        return EXIT_FAILURE;
    result = testArenaTransforms(arena);
    Arena_destroy(arena);
    if (result != EXIT_SUCCESS)
        return result;
    return testAllocationFailure();
}
