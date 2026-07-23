/**
 * Bindings for the C <stdlib.h> APIs supported by Laser-D.
 *
 * Derived from druntime's core.stdc.stdlib.
 */
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
