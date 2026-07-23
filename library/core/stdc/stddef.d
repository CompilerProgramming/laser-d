/**
 * Bindings for the C <stddef.h> types supported by Laser-D.
 *
 * Derived from druntime's core.stdc.stddef.
 */
module core.stdc.stddef;

alias nullptr_t = typeof(null);

// Laser-D currently supports 64-bit targets.
alias size_t = ulong;
alias ptrdiff_t = long;

version (Windows)
    alias wchar_t = wchar;
else
    alias wchar_t = dchar;
