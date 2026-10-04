# UTF-8 processing: laserd.utf8proc

`laserd.utf8proc` provides UTF-8 validation, decoding and encoding, Unicode
categories, case mapping, display width, grapheme boundaries, normalization,
and case folding. The supported character data is Unicode 17.0.0.

Inspection functions use caller-owned storage or return values.
`utf8proc_transform` allocates its result through a borrowed [Arena](memory.md);
release it with `utf8proc_buffer_destroy`. UTF-16/UTF-32 codecs and
malloc-allocating convenience functions such as `utf8proc_map` and
`utf8proc_NFC` are not provided.

## Scalar types and constants

Options are bit flags; category constants are Unicode general categories;
negative error values distinguish allocation, overflow, invalid encoding,
unassigned characters, and invalid option combinations.

```d
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
```

## Native functions

```d
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
```

| Functions | Contract |
| --- | --- |
| `utf8proc_version`, `utf8proc_unicode_version`, `utf8proc_errmsg` | Borrowed zero-terminated version/error strings. |
| `utf8proc_iterate` | Decode one UTF-8 codepoint; return consumed bytes or a negative error. |
| `utf8proc_codepoint_valid`, `utf8proc_encode_char` | Validate a scalar or encode into caller storage (allow four bytes). |
| `utf8proc_decompose` | Decompose into caller-provided codepoint storage; null output/zero capacity queries required codepoint count. Negative results are errors. |
| `utf8proc_reencode` | Convert a mutable codepoint buffer to UTF-8 in place; returns byte count or error. Buffer must include room for the trailing zero. |
| `utf8proc_grapheme_break_stateful` | Stateful boundary check between successive codepoints; initialize state to zero and retain it while scanning. |
| `utf8proc_tolower`, `utf8proc_toupper`, `utf8proc_totitle` | Simple single-codepoint case mapping. |
| `utf8proc_islower`, `utf8proc_isupper` | Case predicates. |
| `utf8proc_charwidth`, `utf8proc_charwidth_ambiguous` | Display width and ambiguous-width predicate. |
| `utf8proc_category`, `utf8proc_category_string` | Category value and borrowed category abbreviation. |

## Arena-owned transformations

```d
struct Utf8procBuffer
{
    char[] data;
    void* allocation;
    Arena* arena;
    utf8proc_ssize_t error;
    bool ok();
}
Utf8procBuffer utf8proc_transform(Arena* arena, const(char)[] input,
                                utf8proc_option_t options);
void utf8proc_buffer_destroy(ref Utf8procBuffer buffer);
```

`ok` tests `error >= 0`. `data` is the used UTF-8 prefix of `allocation`; it must
not be freed independently. The arena is borrowed and must outlive the result.
Destroy the result once through `utf8proc_buffer_destroy`, which releases the
complete allocation and clears its pointers (but preserves the error code).
Copies alias the same allocation; destroying one invalidates the others.

Use `UTF8PROC_STABLE | UTF8PROC_COMPOSE` for NFC and add `UTF8PROC_COMPAT` for
NFKC; `UTF8PROC_CASEFOLD` requests full case folding. Input is length-delimited
and can contain NUL bytes when `UTF8PROC_NULLTERM` is not set. That native flag
requests zero-terminated processing instead, so do not set it for arbitrary
slices. Empty successful output may have null data and allocation pointers.

## Using the library

Link `laserd_utf8proc`; Arena-backed
transforms also use `laserd_rpmalloc` and its platform dependencies. See
[building](building.md) and [Arena](memory.md).

## Implementation Details

Source: `library/laserd/utf8proc.d`.

Integration coverage: `library/test/utf8proc.d` (CTest `utf8proc`).

The binding uses vendored utf8proc 2.11.3 and preserves native names for its
allocation-free functions. `utf8proc_transform` uses `utf8proc_decompose` and
`utf8proc_reencode` with arena-owned working storage. The former handwritten
`laserd.uni` predicates are not part of the supported library surface.
