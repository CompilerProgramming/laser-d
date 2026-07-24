# Laser-D standard library

This directory contains the source modules distributed with Laser-D.

The initial `core.stdc` modules are bindings to the platform C runtime. They
contain ABI types, constants, and `extern(C)` declarations, but no D runtime,
garbage collector, module lifecycle, or hidden initialization.

Only APIs verified by the Laser-D test suite are part of the supported subset.
The modules are derived from the corresponding druntime bindings and adapted
to use only Laser-D language features.

`object.d` is the minimal implicit module distributed with the compiler.
Standard-library integration tests live under `library/test` and are compiled
directly with Laser-D. Linux requires position-independent code because its
toolchain links executables as PIE by default:

```bash
platform_flags=()
if [[ "$(uname -s)" == "Linux" ]]; then
    platform_flags=(-fPIC)
fi
./laserd -conf= "${platform_flags[@]}" \
    -Ilibrary -run library/test/core_stdc.d
```

CMake builds, tests, installs, and packages the standard library. Configure it
after building the compiler with Dub, using the same release configuration as
CI:

```bash
cmake -S library -B generated/cmake-library \
    -DCMAKE_BUILD_TYPE=Release \
    -DLASERD_COMPILER="$PWD/laserd"
cmake --build generated/cmake-library --config Release
ctest --test-dir generated/cmake-library \
    --build-config Release --output-on-failure
cmake --build generated/cmake-library \
    --config Release --target package
```

The `checksum` component demonstrates the intended model for C-backed Laser-D
libraries. CMake builds `checksum.c` as a native static library, Laser-D imports
it through `laserd.checksum`, and CTest runs a program that calls both the raw
`extern(C)` function and its slice-based wrapper. Installation includes the
archive, C header, `.d` import, CMake helper, and a standalone rebuildable
example under `share/laserd/examples/checksum`.

The `rpmalloc` component is the first production C-backed library. It builds
rpmalloc 2.0.1 as `laserd_rpmalloc`, without replacing the process-wide C
allocator, and enables both its general allocation API and its explicit,
single-thread-owned heap API. Laser-D programs import declarations from
`laserd.rpmalloc`. The CTest integration program exercises both API families.

The `hash` component provides the Laser-D module `laserd.hash`. It is an
insertion-ordered port of the public-domain `st` C hash table with machine-word
keys and values. It retains the original binless linear-search representation
for small tables, the packed 8/16/32/64-bit bin indices for larger tables, the
combined entries-and-bins allocation, probing sequence, and rebuild thresholds.
A caller supplies and retains ownership of an `rpmalloc_heap_t`; a table uses
that heap for its own allocation and growth but never clears or releases it.
Numeric, C-string, and ASCII case-insensitive C-string policies are predefined,
and callers may supply compatible hash and comparison function pointers.
Allocation failure is returned as `null` from creation/copying and as
`ST_ERROR` from operations that may grow the table.

The `core.stdc` modules do not produce a library archive because they contain
declarations only; programs link those APIs directly to the platform C runtime.
