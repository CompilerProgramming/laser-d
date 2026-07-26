// CMake links this focused ABI test with the vendored Foundation C library.
import core.stdc.stdlib : EXIT_FAILURE, EXIT_SUCCESS;
import laserd.foundation.base64 :
    base64_decode,
    base64_encode,
    decode,
    encode;
import laserd.foundation.hash : hash, hashBytes;

extern(C) int main()
{
    enum text = "engine";
    auto bytes = cast(const(ubyte)[]) text;

    if (hash(bytes.ptr, bytes.length) != 0x39c8cc157cfd24f8UL)
        return EXIT_FAILURE;
    if (hashBytes(bytes) != 0x39c8cc157cfd24f8UL)
        return EXIT_FAILURE;

    char[9] encoded;
    if (encode(bytes, encoded[]) != 9)
        return EXIT_FAILURE;
    if (encoded[0] != 'Z' || encoded[1] != 'W' ||
        encoded[2] != '5' || encoded[3] != 'n' ||
        encoded[4] != 'a' || encoded[5] != 'W' ||
        encoded[6] != '5' || encoded[7] != 'l' ||
        encoded[8] != 0)
        return EXIT_FAILURE;

    ubyte[6] decoded;
    if (decode(encoded[0 .. 8], decoded[]) != bytes.length)
        return EXIT_FAILURE;
    foreach (i; 0 .. bytes.length)
        if (decoded[i] != bytes[i])
            return EXIT_FAILURE;

    char[5] shortEncoding;
    if (base64_encode(
            bytes.ptr, bytes.length,
            shortEncoding.ptr, shortEncoding.length) != 5)
        return EXIT_FAILURE;
    if (shortEncoding[4] != 0)
        return EXIT_FAILURE;

    ubyte[3] shortDecode;
    if (base64_decode(
            encoded.ptr, 8, shortDecode.ptr, shortDecode.length) != 3)
        return EXIT_FAILURE;

    return EXIT_SUCCESS;
}
