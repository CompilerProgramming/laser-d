/**
 * C ABI scalar types supported by Laser-D.
 *
 * Derived from druntime's core.stdc.config.
 */
module core.stdc.config;

version (Windows)
{
    alias c_long = int;
    alias c_ulong = uint;
}
else
{
    // Laser-D currently targets 64-bit Unix platforms.
    alias c_long = long;
    alias c_ulong = ulong;
}
