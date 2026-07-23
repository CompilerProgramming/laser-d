/**
 * Bindings for the C <stdint.h> types supported by Laser-D.
 *
 * Derived from druntime's core.stdc.stdint.
 */
module core.stdc.stdint;

public import core.stdc.stddef : ptrdiff_t, size_t;

alias int8_t = byte;
alias uint8_t = ubyte;
alias int16_t = short;
alias uint16_t = ushort;
alias int32_t = int;
alias uint32_t = uint;
alias int64_t = long;
alias uint64_t = ulong;

alias intptr_t = ptrdiff_t;
alias uintptr_t = size_t;
alias intmax_t = long;
alias uintmax_t = ulong;

enum INT8_MIN = byte.min;
enum INT8_MAX = byte.max;
enum UINT8_MAX = ubyte.max;
enum INT16_MIN = short.min;
enum INT16_MAX = short.max;
enum UINT16_MAX = ushort.max;
enum INT32_MIN = int.min;
enum INT32_MAX = int.max;
enum UINT32_MAX = uint.max;
enum INT64_MIN = long.min;
enum INT64_MAX = long.max;
enum UINT64_MAX = ulong.max;
enum INTPTR_MIN = ptrdiff_t.min;
enum INTPTR_MAX = ptrdiff_t.max;
enum UINTPTR_MAX = size_t.max;
enum INTMAX_MIN = intmax_t.min;
enum INTMAX_MAX = intmax_t.max;
enum UINTMAX_MAX = uintmax_t.max;
