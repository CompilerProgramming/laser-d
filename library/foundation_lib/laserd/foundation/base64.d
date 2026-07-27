/**
 * Laser-D bindings for Foundation's allocation-free Base64 codec.
 *
 * The caller owns both buffers. `encode` includes the trailing zero in its
 * return value, matching the C API; `decode` returns decoded byte count.
 */
module laserd.foundation.base64;

import core.stdc.stddef : size_t;

extern(C) size_t base64_encode(
    const(void)* source,
    size_t size,
    char* destination,
    size_t capacity);

extern(C) size_t base64_decode(
    const(char)* source,
    size_t size,
    void* destination,
    size_t capacity);

size_t encode(const(ubyte)[] source, char[] destination)
{
    return base64_encode(
        source.ptr, source.length, destination.ptr, destination.length);
}

size_t decode(const(char)[] source, ubyte[] destination)
{
    return base64_decode(
        source.ptr, source.length, destination.ptr, destination.length);
}
