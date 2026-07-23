#include "checksum.h"

uint32_t laserd_checksum(const uint8_t *data, size_t length)
{
    uint32_t result = 0;

    for (size_t index = 0; index < length; ++index)
        result += data[index];

    return result;
}
