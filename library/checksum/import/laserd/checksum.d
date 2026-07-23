/**
 * Laser-D binding and value-oriented wrapper for the example C checksum
 * library.
 */
module laserd.checksum;

import core.stdc.stddef : size_t;
import core.stdc.stdint : uint32_t;

extern(C) uint32_t laserd_checksum(const(ubyte)* data, size_t length);

uint32_t checksum(const(ubyte)[] data)
{
    return laserd_checksum(data.ptr, data.length);
}
