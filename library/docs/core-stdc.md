# C runtime bindings: core.stdc

Sources: `library/core/stdc/*.d`. These are declarations bound directly to
the platform C runtime, with no Laser-D archive or hidden initialization.
The following is the shipped subset, not all of the C standard library.

C pointer APIs retain their native buffer, lifetime, and termination contracts.
Pass zero-terminated strings where a C string is required; a D slice does not
automatically supply a terminator. Pair C allocations with C `free`, and opened
`FILE*` streams with `fclose`. Counts in `fread`/`fwrite` are element counts;
memory operations use byte counts. `memcpy` requires nonoverlapping regions;
use `memmove` when they overlap. Variadic calls require C-compatible arguments.

Integration coverage: `library/test/core_stdc.d` (CTest `core_stdc`).

## core.stdc.config

C `long`/`unsigned long` aliases differ between Windows and 64-bit Unix.

```d
module core.stdc.config;

version (Windows)
{
    alias c_long = int;
    alias c_ulong = uint;
}
else
{

    alias c_long = long;
    alias c_ulong = ulong;
}
```

## core.stdc.stddef

Pointer-sized integer aliases and the platform C wide-character type.

```d
module core.stdc.stddef;

alias nullptr_t = typeof(null);

alias size_t = ulong;
alias ptrdiff_t = long;

version (Windows)
    alias wchar_t = wchar;
else
    alias wchar_t = dchar;
```

## core.stdc.stdint

Fixed-width and pointer-width integers, limits, and public reexports of `size_t` and `ptrdiff_t`.

```d
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
```

## core.stdc.stdarg

C variadic ABI storage on x86-64. The Unix structure contains register offsets and argument-area pointers; no `va_start`/`va_arg` functions are declared here.

```d
module core.stdc.stdarg;

version (X86_64)
{
    version (Windows)
    {
        alias va_list = char*;
    }
    else
    {
        struct __va_list_tag
        {
            uint offset_regs;
            uint offset_fpregs;
            void* stack_args;
            void* reg_args;
        }

        alias __va_list = __va_list_tag;
        alias va_list = __va_list*;
    }
}
```

## core.stdc.stdio

Opaque `FILE`, seek constants, file and formatted I/O. Signatures below reproduce the binding, including its declared `long` seek offset and result.

```d
module core.stdc.stdio;

import core.stdc.stddef : size_t;

extern(C) struct FILE;

enum EOF = -1;
enum SEEK_SET = 0;
enum SEEK_CUR = 1;
enum SEEK_END = 2;

extern(C)
{
    int remove(const char* filename);
    int rename(const char* oldName, const char* newName);

    FILE* fopen(const char* filename, const char* mode);
    int fclose(FILE* stream);
    int fflush(FILE* stream);

    size_t fread(void* destination, size_t size, size_t count, FILE* stream);
    size_t fwrite(const void* source, size_t size, size_t count, FILE* stream);
    int fseek(FILE* stream, long offset, int origin);
    long ftell(FILE* stream);
    void rewind(FILE* stream);

    int fgetc(FILE* stream);
    char* fgets(char* destination, int count, FILE* stream);
    int fputc(int character, FILE* stream);
    int fputs(const char* text, FILE* stream);

    int puts(const char* text);
    int printf(const char* format, ...);
    int sprintf(char* destination, const char* format, ...);
    int snprintf(char* destination, size_t count, const char* format, ...);

    int feof(FILE* stream);
    int ferror(FILE* stream);
    void clearerr(FILE* stream);
    void perror(const char* prefix);
}
```

## core.stdc.stdlib

Allocation, process exit, numeric conversion, sorting/searching, and integer arithmetic. Division structs contain quotient (`quot`) and remainder (`rem`); `compare_fp_t` is a C comparison callback.

```d
module core.stdc.stdlib;

import core.stdc.config : c_long, c_ulong;
public import core.stdc.stddef;

alias compare_fp_t = extern(C) int function(const void*, const void*);

struct div_t
{
    int quot;
    int rem;
}

struct ldiv_t
{
    c_long quot;
    c_long rem;
}

struct lldiv_t
{
    long quot;
    long rem;
}

enum EXIT_SUCCESS = 0;
enum EXIT_FAILURE = 1;

extern(C)
{
    void* malloc(size_t size);
    void* calloc(size_t count, size_t size);
    void* realloc(void* pointer, size_t size);
    void free(void* pointer);

    void abort();
    void exit(int status);

    int atoi(const char* text);
    c_long atol(const char* text);
    long atoll(const char* text);
    double atof(const char* text);

    c_long strtol(const char* text, char** end, int base);
    c_ulong strtoul(const char* text, char** end, int base);
    long strtoll(const char* text, char** end, int base);
    ulong strtoull(const char* text, char** end, int base);
    double strtod(const char* text, char** end);
    float strtof(const char* text, char** end);

    void* bsearch(const void* key, const void* base, size_t count,
                  size_t size, compare_fp_t compare);
    void qsort(void* base, size_t count, size_t size, compare_fp_t compare);

    int abs(int value);
    c_long labs(c_long value);
    long llabs(long value);
    div_t div(int numerator, int denominator);
    ldiv_t ldiv(c_long numerator, c_long denominator);
    lldiv_t lldiv(long numerator, long denominator);
}
```

## core.stdc.string

Byte memory operations and zero-terminated C-string operations. These functions do not perform Unicode normalization or character-aware indexing.

```d
module core.stdc.string;

import core.stdc.stddef : size_t;

extern(C)
{
    const(void)* memchr(const void* memory, int value, size_t count);
    int memcmp(const void* left, const void* right, size_t count);
    void* memcpy(void* destination, const void* source, size_t count);
    void* memmove(void* destination, const void* source, size_t count);
    void* memset(void* destination, int value, size_t count);

    char* strcat(char* destination, const char* source);
    const(char)* strchr(const char* text, int value);
    int strcmp(const char* left, const char* right);
    int strcoll(const char* left, const char* right);
    char* strcpy(char* destination, const char* source);
    size_t strcspn(const char* text, const char* rejected);
    const(char)* strerror(int error);
    size_t strlen(const char* text);
    char* strncat(char* destination, const char* source, size_t count);
    int strncmp(const char* left, const char* right, size_t count);
    char* strncpy(char* destination, const char* source, size_t count);
    const(char)* strpbrk(const char* text, const char* accepted);
    const(char)* strrchr(const char* text, int value);
    size_t strspn(const char* text, const char* accepted);
    const(char)* strstr(const char* text, const char* sought);
    char* strtok(char* text, const char* delimiters);
    size_t strxfrm(char* destination, const char* source, size_t count);
}
```
