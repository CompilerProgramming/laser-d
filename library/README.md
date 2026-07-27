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

On Windows, CMake propagates the required system libraries automatically.
Programs that invoke `laserd` directly must name them explicitly. In
particular, every direct link that includes `laserd_rpmalloc.lib` also includes
`advapi32.lib`, which supplies the process-token APIs used by rpmalloc:

```powershell
bin\laserd.exe app.d lib\laserd_rpmalloc.lib advapi32.lib
```

This requirement also applies when `laserd_rpmalloc.lib` is reached through
`laserd.hash` or Foundation. A direct Foundation link includes
`laserd_foundation.lib`, `laserd_rpmalloc.lib`, `user32.lib`, `shell32.lib`,
and `advapi32.lib`. The repository CMake build propagates these dependencies
from its native targets; consumers defining their own targets must preserve
the same transitive platform libraries.

Library source paths mirror module packages directly. Upstream-compatible
modules such as `object` and `core.stdc` retain their established names under
the library root. Laser-D-owned modules and cross-library facades live under
`library/laserd`. Code owned by a native dependency lives in that dependency's
`laserd` directory, with native adapter sources under `laserd/c`. All library
and native interoperability tests are collected under `library/test`.

The `rpmalloc` component is the first production C-backed library. It builds
rpmalloc 2.0.1 as `laserd_rpmalloc`, without replacing the process-wide C
allocator, and enables both its general allocation API and its explicit,
single-thread-owned heap API. Laser-D programs import the
implementation-neutral `laserd.memory` module. Its public names include
`Heap`, `allocate`, `free`, `acquireHeap`, and `allocateFromHeap`; native
rpmalloc names remain private ABI details. The CTest integration program
exercises both API families.

`laserd.result` provides the pure Laser-D value types `Optional` and `Result`.
Laser-D has no exceptions, because D's exception hierarchy is built on classes,
so a fallible operation reports failure as ordinary returned data. `Optional`
carries a value which may be absent; `Result` carries either a value or an
error, and its value type may be `void` for operations which produce no value
on success. Both are plain value types with no allocation, runtime metadata, or
hidden control flow. A `Result` stores its value and error in overlapping
storage, which is sound because Laser-D rejects destructors, postblits, and
copy or move constructors, so no member carries lifecycle behaviour.

Every accessor is total. The language cannot require a caller to inspect a
result: `@disable` is rejected, so construction cannot be routed through a
checked path, and destructors are rejected, so an ignored value cannot be
detected when it goes out of scope. The module therefore has no operation which
is undefined on the absent side. A caller supplies a fallback with `orElse`,
`valueOr`, or `errorOr`, or takes a pointer accessor which is `null` in the
states carrying no data. Pointer accessors refer into the value they were taken
from and do not outlive it. `mapValue` and `mapValueContext` transform a
successful value through an ordinary function pointer, with context passed
explicitly because Laser-D has no capturing delegates. The representation is
uniform for every element type; a pointer element deliberately does not use
`null` as its empty representation, since a Laser-D pointer is nullable and a
present `null` would otherwise be indistinguishable from an absent value.

The pure Laser-D module `laserd.hash` is an
insertion-ordered port of the public-domain `st` C hash table with machine-word
keys and values. It retains the original binless linear-search representation
for small tables, the packed 8/16/32/64-bit bin indices for larger tables, the
combined entries-and-bins allocation, probing sequence, and rebuild thresholds.
A fidelity test checks the original numeric, C-string, case-insensitive, and
incremental hash algorithms against vectors produced by the C source.
Comparison callbacks and iteration may rebuild the table; searches detect the
changed rebuild counter, discard cached entry locations, and retry.
A caller supplies and retains ownership of a `laserd.memory.Heap`; a table uses
that heap for its own allocation and growth but never clears or releases it.
Numeric, C-string, and ASCII case-insensitive C-string policies are predefined,
and callers may supply compatible hash and comparison function pointers.
Allocation failure is returned as `null` from creation/copying and as
`ST_ERROR` from operations that may grow the table.

The `core.stdc` modules do not produce a library archive because they contain
declarations only; programs link those APIs directly to the platform C runtime.

`std.traits` is a deliberately reduced Phobos-compatible module. Its tested
surface contains common type-category predicates, function/field inspection,
basic qualifier constructors, and several simple type helpers. The module
lists deferred upstream groups in comments so later imports have an explicit
review queue. Its library test is an ordinary program adapted from upstream
unittest ideas, since Laser-D has no unittest blocks.

`std.typecons` is not currently distributed. Its central facilities depend on
language or runtime features outside Laser-D, and exporting only a small,
materially incompatible Tuple would overstate Phobos compatibility.

The vendored Foundation library is built as `laserd_foundation`. The initial
reviewed interface deliberately exposes only `laserd.foundation.base64` and
`laserd.foundation.hash`. These operations are portable, stateless,
allocation-free, and do not require Foundation global initialization. Their
wrappers accept Laser-D slices while preserving the raw `extern(C)` entry
points.

Other Foundation modules are not yet part of the supported Laser-D interface.
In particular, MD5/SHA and containers allocate through Foundation's global
memory system; threading, process, filesystem, and stream modules carry
platform or lifecycle requirements; and callback- or variadic-heavy APIs need
separate ABI review. They should be exposed only alongside focused tests and a
documented ownership and initialization model.

`laserd.foundation.lifecycle` initializes Foundation with rpmalloc through a
native adapter. Foundation owns the process-wide rpmalloc lifecycle between
`initialize` and `finalize`; an application must not independently initialize
or finalize rpmalloc during that interval. Foundation-created threads invoke
rpmalloc's per-thread initialization and finalization callbacks. Initialization
and finalization are idempotent.

Foundation's mutex, semaphore, and beacon APIs are intentionally not exposed.
Laser-D plans to use nsync for public synchronization primitives, avoiding two
overlapping synchronization interfaces. Foundation may continue using its
private primitives internally.

`laserd.thread` provides the initial thread-management surface:
opaque thread handles, callback-based creation, start, join, destruction,
status queries, current-thread identifiers, sleep, and yield. Foundation must
be initialized first. A Foundation-created worker automatically establishes
and releases Foundation and rpmalloc per-thread state around its callback.
Destruction joins a started worker if it has not already been joined.

Thread signalling, affinity, externally-created thread registration, and
caller-owned `Thread` storage is not yet exposed. Synchronization between
threads will be supplied separately rather than exposing Foundation's internal
beacon.

Foundation process and pipe support is exposed through the narrow
`laserd.system` module. Processes and streams are opaque.
Executable paths, working directories, and arguments are copied into the
process object. Redirected standard streams are borrowed from their process
and are released when the process is destroyed.
Before destroying a detached process, callers must successfully wait for it,
or kill it and then wait for termination.

The stream surface contains only raw byte reads and writes, flush, end and
availability queries, and destruction. Unnamed pipes support allocation and
closing either endpoint. Native handles/file descriptors, stream vtables,
typed stream serialization, platform-specific process launch modes, and
process-global exit operations are intentionally not exposed.

nsync 1.30.0 supplies Laser-D's public synchronization layer. CMake builds
only its C static library as `laserd_nsync`; the C++ library and upstream test
suite are disabled in the Laser-D parent build. Supported targets are x86-64
Windows, Linux, and macOS.

`laserd.thread` also exposes zero-initializable `Mutex` reader/writer locks and
`Condition` variables. Their reviewed 64-bit ABI occupies
16 bytes each and is checked by both native C static assertions and Laser-D
static assertions. Grouping synchronization with thread management keeps the
public module organized by purpose rather than backing library. The integration
test uses a condition-variable handshake between a Foundation worker and the
main thread, and also covers exclusive, reader, and non-blocking mutex
acquisition.

Successful exclusive and reader acquisitions have acquire semantics; releasing
either mode has release semantics. A release happens before a later successful
acquisition of the same mutex, so ordinary writes made while holding it are
visible to the later holder. Concurrent reader holders must only read protected
data, and mutation requires the exclusive mode.

`Condition` variables use Mesa semantics. Waiting releases the mutex with
release semantics and reacquires it with acquire semantics before returning.
Signalling and broadcasting only wake waiters and do not publish unprotected
data independently. Change and test the predicate while holding the same mutex,
and retest it in a loop after every wakeup.

A successful thread start publishes the argument data initialized before
`start` to the callback. A completed `join` makes the callback's preceding
writes visible to the joining thread; the argument and referenced storage must
remain alive until then. Laser-D still has no `shared` qualifier or
language-level atomics. Every conflicting concurrent access must be protected
by these mutex operations or by another explicitly reviewed foreign
synchronization API.

Timed waits, cancellation notes, counters, once initialization, wait sets, and
conditional critical sections remain unexposed pending focused API and ABI
review.
