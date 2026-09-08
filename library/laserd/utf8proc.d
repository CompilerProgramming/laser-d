/**
 * Laser-D binding and Arena-backed wrapper for utf8proc 2.11.3.
 *
 * The native allocation-free API retains utf8proc's names. Functions such as
 * `utf8proc_map` and `utf8proc_NFC`, which allocate with `malloc`, are
 * deliberately not declared. Use `utf8proc_transform` instead.
 */
module laserd.utf8proc;

import core.stdc.stddef : ptrdiff_t, size_t;
import laserd.memory : Arena;

alias utf8proc_int32_t = int;
alias utf8proc_uint8_t = ubyte;
alias utf8proc_ssize_t = ptrdiff_t;
alias utf8proc_size_t = size_t;
alias utf8proc_bool = bool;
alias utf8proc_option_t = int;
alias utf8proc_category_t = int;

enum UTF8PROC_NULLTERM = 1 << 0;
enum UTF8PROC_STABLE = 1 << 1;
enum UTF8PROC_COMPAT = 1 << 2;
enum UTF8PROC_COMPOSE = 1 << 3;
enum UTF8PROC_DECOMPOSE = 1 << 4;
enum UTF8PROC_IGNORE = 1 << 5;
enum UTF8PROC_REJECTNA = 1 << 6;
enum UTF8PROC_NLF2LS = 1 << 7;
enum UTF8PROC_NLF2PS = 1 << 8;
enum UTF8PROC_NLF2LF = UTF8PROC_NLF2LS | UTF8PROC_NLF2PS;
enum UTF8PROC_STRIPCC = 1 << 9;
enum UTF8PROC_CASEFOLD = 1 << 10;
enum UTF8PROC_CHARBOUND = 1 << 11;
enum UTF8PROC_LUMP = 1 << 12;
enum UTF8PROC_STRIPMARK = 1 << 13;
enum UTF8PROC_STRIPNA = 1 << 14;

enum UTF8PROC_ERROR_NOMEM = -1;
enum UTF8PROC_ERROR_OVERFLOW = -2;
enum UTF8PROC_ERROR_INVALIDUTF8 = -3;
enum UTF8PROC_ERROR_NOTASSIGNED = -4;
enum UTF8PROC_ERROR_INVALIDOPTS = -5;

enum UTF8PROC_CATEGORY_CN = 0;
enum UTF8PROC_CATEGORY_LU = 1;
enum UTF8PROC_CATEGORY_LL = 2;
enum UTF8PROC_CATEGORY_LT = 3;
enum UTF8PROC_CATEGORY_LM = 4;
enum UTF8PROC_CATEGORY_LO = 5;
enum UTF8PROC_CATEGORY_MN = 6;
enum UTF8PROC_CATEGORY_MC = 7;
enum UTF8PROC_CATEGORY_ME = 8;
enum UTF8PROC_CATEGORY_ND = 9;
enum UTF8PROC_CATEGORY_NL = 10;
enum UTF8PROC_CATEGORY_NO = 11;
enum UTF8PROC_CATEGORY_PC = 12;
enum UTF8PROC_CATEGORY_PD = 13;
enum UTF8PROC_CATEGORY_PS = 14;
enum UTF8PROC_CATEGORY_PE = 15;
enum UTF8PROC_CATEGORY_PI = 16;
enum UTF8PROC_CATEGORY_PF = 17;
enum UTF8PROC_CATEGORY_PO = 18;
enum UTF8PROC_CATEGORY_SM = 19;
enum UTF8PROC_CATEGORY_SC = 20;
enum UTF8PROC_CATEGORY_SK = 21;
enum UTF8PROC_CATEGORY_SO = 22;
enum UTF8PROC_CATEGORY_ZS = 23;
enum UTF8PROC_CATEGORY_ZL = 24;
enum UTF8PROC_CATEGORY_ZP = 25;
enum UTF8PROC_CATEGORY_CC = 26;
enum UTF8PROC_CATEGORY_CF = 27;
enum UTF8PROC_CATEGORY_CS = 28;
enum UTF8PROC_CATEGORY_CO = 29;

extern(C):

const(char)* utf8proc_version();
const(char)* utf8proc_unicode_version();
const(char)* utf8proc_errmsg(utf8proc_ssize_t errorCode);
utf8proc_ssize_t utf8proc_iterate(
    const(utf8proc_uint8_t)* input,
    utf8proc_ssize_t length,
    utf8proc_int32_t* codepoint);
utf8proc_bool utf8proc_codepoint_valid(utf8proc_int32_t codepoint);
utf8proc_ssize_t utf8proc_encode_char(
    utf8proc_int32_t codepoint,
    utf8proc_uint8_t* output);
utf8proc_ssize_t utf8proc_decompose(
    const(utf8proc_uint8_t)* input,
    utf8proc_ssize_t length,
    utf8proc_int32_t* output,
    utf8proc_ssize_t outputLength,
    utf8proc_option_t options);
utf8proc_ssize_t utf8proc_reencode(
    utf8proc_int32_t* buffer,
    utf8proc_ssize_t length,
    utf8proc_option_t options);
utf8proc_bool utf8proc_grapheme_break_stateful(
    utf8proc_int32_t first,
    utf8proc_int32_t second,
    utf8proc_int32_t* state);
utf8proc_int32_t utf8proc_tolower(utf8proc_int32_t codepoint);
utf8proc_int32_t utf8proc_toupper(utf8proc_int32_t codepoint);
utf8proc_int32_t utf8proc_totitle(utf8proc_int32_t codepoint);
int utf8proc_islower(utf8proc_int32_t codepoint);
int utf8proc_isupper(utf8proc_int32_t codepoint);
int utf8proc_charwidth(utf8proc_int32_t codepoint);
utf8proc_bool utf8proc_charwidth_ambiguous(utf8proc_int32_t codepoint);
utf8proc_category_t utf8proc_category(utf8proc_int32_t codepoint);
const(char)* utf8proc_category_string(utf8proc_int32_t codepoint);

extern(D):

/**
 * UTF-8 output allocated by `utf8proc_transform` through `arena`.
 * `allocation` is the complete block; `data` is the used UTF-8 prefix.
 */
struct Utf8procBuffer
{
    char[] data;
    void* allocation;
    Arena* arena;
    utf8proc_ssize_t error;

    bool ok() { return error >= 0; }
}

/**
 * Applies utf8proc normalization/case-folding options using only `arena`.
 * The input is length-delimited and may contain embedded NUL bytes.
 */
Utf8procBuffer utf8proc_transform(
    Arena* arena,
    const(char)[] input,
    utf8proc_option_t options)
{
    Utf8procBuffer result;
    result.arena = arena;
    if (arena is null)
    {
        result.error = UTF8PROC_ERROR_NOMEM;
        return result;
    }
    if (input.length > cast(size_t) ptrdiff_t.max)
    {
        result.error = UTF8PROC_ERROR_OVERFLOW;
        return result;
    }

    utf8proc_ssize_t required = utf8proc_decompose(
        cast(const(ubyte)*) input.ptr,
        cast(utf8proc_ssize_t) input.length,
        null,
        0,
        options);
    if (required < 0)
    {
        result.error = required;
        return result;
    }
    if (required == 0)
        return result;
    if (cast(size_t) required > (size_t.max - 1) / int.sizeof)
    {
        result.error = UTF8PROC_ERROR_OVERFLOW;
        return result;
    }

    size_t bytes = cast(size_t) required * int.sizeof + 1;
    int* working = cast(int*) arena.aligned_alloc(int.alignof, bytes);
    if (working is null)
    {
        result.error = UTF8PROC_ERROR_NOMEM;
        return result;
    }
    result.allocation = working;

    utf8proc_ssize_t decomposed = utf8proc_decompose(
        cast(const(ubyte)*) input.ptr,
        cast(utf8proc_ssize_t) input.length,
        working,
        required,
        options);
    if (decomposed < 0)
    {
        result.error = decomposed;
        utf8proc_buffer_destroy(result);
        return result;
    }

    utf8proc_ssize_t encoded = utf8proc_reencode(working, decomposed, options);
    if (encoded < 0)
    {
        result.error = encoded;
        utf8proc_buffer_destroy(result);
        return result;
    }
    result.data = (cast(char*) working)[0 .. cast(size_t) encoded];
    return result;
}

void utf8proc_buffer_destroy(ref Utf8procBuffer buffer)
{
    if (buffer.arena !is null && buffer.allocation !is null)
        buffer.arena.free(buffer.allocation);
    buffer.data = null;
    buffer.allocation = null;
    buffer.arena = null;
}
