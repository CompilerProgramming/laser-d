# Laser-D

Laser-D is **Lesser-D**: a deliberately smaller dialect of the D programming
language, implemented as a fork of the DMD compiler frontend.

Laser-D is not intended to mean “D in BetterC mode.” BetterC does not define a
clear language subset as its precise boundary is difficult to infer from
documentation alone. Laser-D instead defines a clear subset of D through its own
specification, implementation, and executable feature tests.

Every Laser-D program is also a D program. Laser-D introduces no new syntax; it
selects a smaller, more explicit part of D.

## Direction

Laser-D aims to combine D's pleasant syntax and compile-time facilities with a
runtime model closer to C:

- no garbage collector or D runtime dependency;
- explicit storage, control flow, function calls, and cleanup;
- predictable interoperability through the C ABI;
- portability across Windows, Linux, and macOS, initially on x86-64;
- powerful compile-time abstraction without hidden runtime machinery; and
- a language boundary specified by focused positive and negative tests.

Robustness is part of the language boundary. A feature should not be retained
merely because it works for a useful special case. Features that have fragile
semantics, depend on unreviewed compiler-generated behavior, or work only for
some combinations of otherwise supported constructs should be restricted or
rejected until they can be given a clear and dependable contract.

## Language character

The guiding principle is that source code should make consequential behavior
visible. Syntax that can conceal allocation, control flow, lifetime,
synchronization, runtime metadata, or an ordinary function call is generally
rejected or replaced by a more explicit D syntax.

Laser-D retains substantial parts of D, including:

- modules and ImportC;
- primitive scalar types, enums, structs, unions, and bit fields;
- fixed arrays, non-owning slices, and string literals;
- ordinary functions, function pointers, and controlled non-capturing
  delegates;
- templates, CTFE, traits, `typeof`, and `is`;
- modern operator overloading, including fixed-storage multidimensional
  indexing;
- `immutable` data;
- C interoperability; and
- deterministic cleanup through `scope(exit)`.

Laser-D rejects many of D's managed, implicit, legacy, or platform-specific
facilities, including:

- GC allocation, associative arrays, and GC-backed array operations;
- classes, interfaces, virtual dispatch, and runtime type/module metadata;
- exceptions, function contracts, module lifecycle functions, struct
  destructors, and postblits;
- capturing closures and delegates;
- language-level threading features;
- user-defined attributes, `@property`, and function calls without
  parentheses;
- string mixins and compile-time I/O;
- reference returns and lifetime annotations;
- legacy D1 operator hooks; and
- inline assembly, vector types, COM, and Objective-C support.

This is not a memory-safe language in the Rust sense. Pointers, manual storage,
and implicitly `@system` code remain available. The objective is instead to
make programs smaller in semantic surface area and easier to audit: calls,
allocation, cleanup, aliasing, and external interaction should be apparent from
the source wherever practical.

Constructors and overloaded operators are narrow, deliberate exceptions to the
preference for explicit calls. They are retained for fixed-storage,
primitive-like value abstractions: constructors make small values convenient to
initialize, while operators allow natural notation for types such as matrices,
big integers, and fixed-precision decimals. Removing operator overloading
entirely would force method-heavy expressions even where the mathematical
meaning of an operator is clearer.

Laser-D cannot reliably prove that every constructor or overload is used only
in this style. Instead, it constrains the mechanisms around them: no hidden GC
allocation, destructors, postblits, exceptions, reference returns, virtual
dispatch, or runtime metadata. Constructors and operators remain subject to all
other Laser-D restrictions and are tested around predictable value semantics.
Code review and library design must enforce the final requirement that their
behavior is unsurprising and appropriate to the notation.

In short:

> Laser-D is D's compile-time power with a smaller, more explicit, C-like
> runtime language.

## Specification and tests

The current design rationale is recorded in [DESIGN.md](DESIGN.md), and the
feature inventory is maintained in [FEATURE_STATUS.md](FEATURE_STATUS.md).
Laser-D-specific language notes are incorporated into the relevant chapters
under [`spec`](spec). Reviewed chapters are also available in the parallel
Markdown specification under [`spec-markdown`](spec-markdown); the Ddoc sources
remain unchanged during the migration.

The executable language specification lives under
[`compiler/test/laser-d`](compiler/test/laser-d). Each accepted feature has a
compilable or runnable test, while rejected forms have focused diagnostic
tests. See the [Laser-D test README](compiler/test/laser-d/README.md) for
instructions.

## Building and testing

### Prerequisites

Building Laser-D requires an installed **full D compiler toolchain**. Use an
upstream DMD installation, or a compatible LDC/GDC installation with its DMD
command-line wrapper. The host compiler must include the normal D runtime and
standard library; a previously built Laser-D compiler is not suitable as the
bootstrap compiler.

The compiler build and test harness are themselves full-D programs and use
features intentionally excluded from Laser-D. In particular, `HOST_DMD` must
refer to the upstream host compiler, not the Dub-built `laserd` executable in
the repository root.

The following tools are required:

- DMD with `dmd` and `rdmd` available on `PATH` (recommended), or compatible
  `ldmd2`/`gdmd` wrappers;
- Dub for building the compiler;
- CMake 3.24 or later for standard-library compilation, testing, installation,
  and packaging;
- Python 3.13 or later for the generated-documentation check;
- a native C++ toolchain;
- Visual Studio or Microsoft C++ Build Tools on Windows; or
- GCC/Clang and the usual development tools on Linux and macOS.

The upstream compiler build documentation currently requires a host D compiler
version 2.079.1 or later.

### CI-equivalent build and test

The following commands mirror the CI workflow. Run them from the repository
root.

On Linux with upstream DMD:

```bash
HOST_DMD="$(command -v dmd)"
export HOST_DMD
REPOSITORY_ROOT="$PWD"

"${HOST_DMD}" --version
dub build dmd:compiler --build=release --compiler="${HOST_DMD}"
./laserd --version

(
    cd compiler/test
    LASERD_COMPILER="${REPOSITORY_ROOT}/laserd" \
        "${HOST_DMD}" -i -run run.d laser-d
)

./laserd -conf= -fPIC -Ilibrary -run library/test/core_stdc.d

cmake -S library -B generated/cmake-library \
    -DCMAKE_BUILD_TYPE=Release \
    -DLASERD_COMPILER="${REPOSITORY_ROOT}/laserd"
cmake --build generated/cmake-library --config Release
ctest --test-dir generated/cmake-library \
    --build-config Release --output-on-failure
cmake --build generated/cmake-library \
    --config Release --target package

python tools/check_markdown_docs.py
git diff --check
```

On macOS, CI uses the DMD-compatible LDC driver because the upstream DMD binary
has proved unreliable on the hosted Intel runner. Use `ldmd2` in place of
`dmd`; omit `-fPIC` from the direct `core_stdc` command, matching CI:

```bash
HOST_DMD="$(command -v ldmd2)"
export HOST_DMD
REPOSITORY_ROOT="$PWD"

"${HOST_DMD}" --version
dub build dmd:compiler --build=release --compiler="${HOST_DMD}"
./laserd --version

(
    cd compiler/test
    LASERD_COMPILER="${REPOSITORY_ROOT}/laserd" \
        "${HOST_DMD}" -i -run run.d laser-d
)

./laserd -conf= -Ilibrary -run library/test/core_stdc.d

cmake -S library -B generated/cmake-library \
    -DCMAKE_BUILD_TYPE=Release \
    -DLASERD_COMPILER="${REPOSITORY_ROOT}/laserd"
cmake --build generated/cmake-library --config Release
ctest --test-dir generated/cmake-library \
    --build-config Release --output-on-failure
cmake --build generated/cmake-library \
    --config Release --target package
```

On Windows, first run from a shell with the Visual Studio x64 build environment
configured. CI performs the equivalent setup before these PowerShell commands:

```powershell
$HostDmd = (Get-Command dmd).Source
$env:HOST_DMD = $HostDmd
$RepositoryRoot = $PWD.Path

& $HostDmd --version
dub build dmd:compiler --build=release --compiler="$HostDmd"
.\laserd.exe --version

Push-Location compiler\test
$env:LASERD_COMPILER = Join-Path $RepositoryRoot "laserd.exe"
& $HostDmd -i -run run.d laser-d
Pop-Location

.\laserd.exe -conf= -Ilibrary -run library\test\core_stdc.d

cmake -S library -B generated\cmake-library `
    -DCMAKE_BUILD_TYPE=Release `
    -DLASERD_COMPILER="$RepositoryRoot\laserd.exe"
cmake --build generated\cmake-library --config Release
ctest --test-dir generated\cmake-library `
    --build-config Release --output-on-failure
cmake --build generated\cmake-library `
    --config Release --target package
```

Dub writes `laserd` (`laserd.exe` on Windows) to the repository root. CPack
writes the native `x86_64` ZIP distribution under `dist/`.

### Run one language test

Pass the test path relative to `compiler/test`, preserving the same separation
between the full host compiler and the compiler under test:

```bash
(
    cd compiler/test
    LASERD_COMPILER="$PWD/../../laserd" \
        "${HOST_DMD}" -i -run run.d laser-d/templates_accepted.d
)
```

```powershell
Push-Location compiler\test
$env:LASERD_COMPILER = Join-Path $RepositoryRoot "laserd.exe"
& $HostDmd -i -run run.d laser-d/templates_accepted.d
Pop-Location
```

### Distribution contents

CMake and CPack name the ZIP for the Laser-D version, native platform, and
`x86_64` architecture. For example:

```text
dist/laser-d-v2.113.0-beta.1-linux-x86_64.zip
```

Each distribution contains:

- `bin/laserd` (`bin/laserd.exe` on Windows);
- an adjacent compiler configuration that automatically adds the packaged
  `import/` directory;
- `import/object.d`, the supported `core.stdc` source modules, and the
  Laser-D-owned modules under `laserd`;
- `lib/liblaserd_rpmalloc.a` (`lib/laserd_rpmalloc.lib` on Windows), the
  `laserd.memory` module, rpmalloc C header, and rpmalloc licence;
- the Foundation and nsync native libraries and their supported Laser-D
  interfaces;
- the project and standard-library documentation and licence.

The `core.stdc` modules remain declarations for the platform C runtime. The
rpmalloc component is built without process-wide `malloc` replacement and
exposes both its general allocator and first-class heap APIs. A distribution
is platform-specific and must be built on its target platform; CI publishes
separate Windows, Linux, and macOS ZIP artifacts.

On Windows, a program linked directly with packaged
`lib\laserd_rpmalloc.lib` must also pass `advapi32.lib` to `laserd`:

```powershell
bin\laserd.exe app.d lib\laserd_rpmalloc.lib advapi32.lib
```

The same dependency applies when rpmalloc is used by `laserd.hash` or
Foundation. Direct Foundation links additionally require `user32.lib` and
`shell32.lib`. The repository CMake build supplies these platform libraries
automatically; direct package consumers must name them.

## Repository layout

This repository is based on DMD and retains its overall structure.

| Directory | Description |
| --- | --- |
| [`compiler`](compiler) | Compiler frontend and build system |
| [`compiler/src`](compiler/src) | Compiler sources and build instructions |
| [`compiler/test`](compiler/test) | Test infrastructure and upstream tests |
| [`compiler/test/laser-d`](compiler/test/laser-d) | Laser-D executable language specification |
| [`library`](library) | Laser-D standard-library source modules, beginning with verified C runtime bindings |
| [`spec`](spec) | Language specification with Laser-D decisions |
| [`spec-markdown`](spec-markdown) | Markdown mirror of reviewed specification chapters |
| [`druntime`](druntime) | Upstream runtime sources; not part of the Laser-D runtime contract |

The upstream DMD project and D language resources are available at
[dlang.org](https://dlang.org) and in the
[DMD repository](https://github.com/dlang/dmd).
