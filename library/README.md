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

The `core.stdc` modules do not produce a library archive because they contain
declarations only; programs link those APIs directly to the platform C runtime.
