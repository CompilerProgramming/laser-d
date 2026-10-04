# Building and using the libraries

The library sources are distributed with Laser-D. Only APIs verified by the
Laser-D test suite are part of the supported subset. API inventories describe
the declarations shipped here, not the entire upstream D or native library.

## Build, test, and package

Build the compiler with Dub first. From the repository root on Linux or macOS:

```bash
cmake -S library -B generated/cmake-library \
    -DCMAKE_BUILD_TYPE=Release \
    -DLASERD_COMPILER="$PWD/laserd"
cmake --build generated/cmake-library --config Release
ctest --test-dir generated/cmake-library \
    --build-config Release --output-on-failure
cmake --build generated/cmake-library --config Release --target package
```

From a Visual Studio x64 PowerShell build environment on Windows:

```powershell
cmake -S library -B generated/cmake-library `
    -DCMAKE_BUILD_TYPE=Release `
    "-DLASERD_COMPILER=$PWD/laserd.exe"
cmake --build generated/cmake-library --config Release
ctest --test-dir generated/cmake-library --build-config Release --output-on-failure
cmake --build generated/cmake-library --config Release --target package
```

List tests with `ctest --test-dir generated/cmake-library -N`; select a test
using `-R`, for example `-R '^memory_facade$'`. Library and native integration
tests live in `library/test`, separately from compiler language tests.

For a direct C-runtime smoke test on Linux or macOS:

```bash
platform_flags=()
if [[ "$(uname -s)" == "Linux" ]]; then
    platform_flags=(-fPIC)
fi
./laserd -conf= "${platform_flags[@]}" \
    -Ilibrary -run library/test/core_stdc.d
```

## Imports and linking

In a checkout, use `library` as the import root, and add `library/rpmalloc`
for `laserd.rpmalloc` and `library/foundation_lib` for `laserd.foundation.*`.
The installed distribution merges these modules under `import/` and supplies
the compiler configuration. Source paths in these references are relative to
the repository root.

Pure Laser-D modules are compiled with the application; there is no separate
archive for `object`, `core.stdc`, `std.traits`, `laserd.result`, or
`laserd.typedesc`. Native dependencies are listed on each API page.

The repository helper in `library/cmake/LaserD.cmake` has this interface:

```cmake
laserd_add_executable(target
    SOURCES source.d
    IMPORT_DIRECTORIES import_root
    LINK_LIBRARIES native_target_or_link_argument)
```

It uses `LASERD_COMPILER`, compiles imported D modules with `-i`, tracks imports
through `-makedeps` and CMake `DEPFILE`, and adds `-fPIC` on Linux. Its custom
link command receives native target archive paths; follow `library/test/CMakeLists.txt`
when supplying platform link arguments. Native CMake targets also declare their
transitive system dependencies for consumers using ordinary CMake linking.

On Windows, direct links involving `laserd_rpmalloc.lib` also need
`advapi32.lib`, including when reached through Arena, arrays, or hash tables:

```powershell
bin/laserd.exe app.d lib/laserd_rpmalloc.lib advapi32.lib
```

A direct Foundation link additionally includes `laserd_foundation.lib`,
`user32.lib`, and `shell32.lib`. Thread synchronization also links
`laserd_nsync.lib`. Foundation links pthread, dl, and m on Linux, and Cocoa,
CoreFoundation, and m on macOS; nsync uses pthread on Unix. Preserve platform
dependencies when writing a custom build.

## Layout and scope

Laser-D-owned modules and facades live under `library/laserd`. Native bindings
live under their dependency's `laserd` directory and C adapters under
`laserd/c`. Vendored dependency READMEs describe upstream projects, not the
complete supported Laser-D API.

`std.typecons` is not distributed. The focused JSON program in
`library/test/typedesc_json.d` is a demonstration, not a public JSON library.
