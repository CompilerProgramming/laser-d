/**
 * Laser-D bindings for Foundation's allocation-free 64-bit Murmur3 hash.
 */
module laserd.foundation.hash;

import core.stdc.stddef : size_t;
import core.stdc.stdint : uint64_t;

alias hash_t = uint64_t;

extern(C) hash_t hash(const(void)* key, size_t length);

hash_t hashBytes(const(ubyte)[] value)
{
    return hash(value.ptr, value.length);
}
