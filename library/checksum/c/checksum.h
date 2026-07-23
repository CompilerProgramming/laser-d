#ifndef LASERD_CHECKSUM_H
#define LASERD_CHECKSUM_H

#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

uint32_t laserd_checksum(const uint8_t *data, size_t length);

#ifdef __cplusplus
}
#endif

#endif
