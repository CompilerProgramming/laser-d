# Laser-D

Laser-D is **Lesser-D**: a deliberately smaller dialect of the D programming
language, implemented as a fork of the DMD compiler frontend.

Laser-D is not intended to mean “D in BetterC mode.” BetterC does not define a
complete language subset, and its precise boundary is difficult to infer from
documentation alone. Laser-D instead defines its language through its own
specification, implementation, and executable feature tests.

Every Laser-D program is also a D program. Laser-D introduces no new syntax; it
selects a smaller, more explicit, and more robust part of D.

## Direction

Laser-D aims to combine D's pleasant syntax and compile-time facilities with a
runtime model closer to C:

- no garbage collector or D runtime dependency;
- explicit storage, control flow, function calls, and cleanup;
- predictable interoperability with C and supported C++ free functions;
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
rejected or replaced by a more explicit D spelling.

Laser-D currently retains substantial parts of D, including:

- modules and ImportC;
- primitive scalar types, enums, structs, unions, and bit fields;
- fixed arrays, non-owning slices, and string literals;
- ordinary functions, function pointers, and controlled non-capturing
  delegates;
- templates, CTFE, traits, `typeof`, and `is`;
- modern operator overloading, including fixed-storage multidimensional
  indexing;
- `immutable` data;
- C interoperability and C++ free-function interoperability; and
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
refer to the upstream host compiler, not the Laser-D executable under
`generated`.

The following tools are required:

- DMD with `dmd` and `rdmd` available on `PATH` (recommended), or compatible
  `ldmd2`/`gdmd` wrappers;
- a native C++ toolchain;
- Visual Studio or Microsoft C++ Build Tools on Windows; or
- GCC/Clang and the usual development tools on Linux and macOS.

The upstream compiler build documentation currently requires a host D compiler
version 2.079.1 or later.

### Build the compiler

From the repository root:

```console
rdmd compiler/src/build.d dmd
```

On Windows PowerShell, the equivalent command is:

```powershell
rdmd compiler\src\build.d dmd
```

The release executable is written beneath the platform-specific generated
directory:

```text
generated/windows/release/64/dmd.exe
generated/linux/release/64/dmd
generated/osx/release/64/dmd
```

The build uses `dmd` from `PATH` by default. To select another full host
compiler explicitly, pass the build variable described by the upstream build
system:

```console
rdmd compiler/src/build.d dmd HOST_DMD=/path/to/dmd
```

### Run the Laser-D tests

The test driver must also be compiled by the full host D compiler. From
`compiler/test`, run the complete Laser-D language suite:

```console
HOST_DMD="$(command -v dmd)" ./run.d laser-d
```

On Windows PowerShell:

```powershell
cd compiler\test
$env:HOST_DMD = (Get-Command dmd).Source
rdmd run.d laser-d
```

To run one test, pass its path relative to `compiler/test`:

```console
./run.d laser-d/templates_accepted.d
```

```powershell
rdmd run.d laser-d/templates_accepted.d
```

The test driver automatically selects the newly built compiler under
`generated` as the compiler under test. `HOST_DMD` is used only to build the
full-D test infrastructure.

## Repository layout

This repository is based on DMD and retains its overall structure.

| Directory | Description |
| --- | --- |
| [`compiler`](compiler) | Compiler frontend and build system |
| [`compiler/src`](compiler/src) | Compiler sources and build instructions |
| [`compiler/test`](compiler/test) | Test infrastructure and upstream tests |
| [`compiler/test/laser-d`](compiler/test/laser-d) | Laser-D executable language specification |
| [`spec`](spec) | Language specification with Laser-D decisions |
| [`spec-markdown`](spec-markdown) | Markdown mirror of reviewed specification chapters |
| [`druntime`](druntime) | Upstream runtime sources; not part of the Laser-D runtime contract |

The upstream DMD project and D language resources are available at
[dlang.org](https://dlang.org) and in the
[DMD repository](https://github.com/dlang/dmd).
