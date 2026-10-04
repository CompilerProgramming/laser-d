# Laser-D libraries

| Library | Modules | Purpose |
| --- | --- | --- |
| [Implicit types](docs/object.md) | `object` | String type aliases |
| [C runtime](docs/core-stdc.md) | `core.stdc.*` | C ABI types, memory, strings, files, and numeric functions |
| [Compile-time traits](docs/traits.md) | `std.traits` | Type predicates and symbol inspection |
| [Optional and result values](docs/result.md) | `laserd.result` | Value-or-absence and value-or-error structs |
| [Type descriptions](docs/typedesc.md) | `laserd.typedesc` | Compile-time descriptor structs and traversal |
| [Arena allocation](docs/memory.md) | `laserd.memory` | Explicit allocation with rpmalloc, fixed-region, and bump backends |
| [Arrays](docs/array.md) | `laserd.array` | Arena-backed arrays and ranges |
| [Hash tables](docs/hash.md) | `laserd.hash` | Insertion-ordered machine-word key/value tables |
| [UTF-8 processing](docs/utf8proc.md) | `laserd.utf8proc` | Unicode inspection, normalization, and case folding |
| [Native allocation](docs/rpmalloc.md) | `laserd.rpmalloc` | rpmalloc allocation and explicit heaps |
| [Foundation](docs/foundation.md) | `laserd.foundation.*` | Base64, hashing, and process-wide lifecycle |
| [Threads and synchronization](docs/thread.md) | `laserd.thread` | Foundation workers and nsync mutexes/conditions |
| [Processes and streams](docs/system.md) | `laserd.system` | Child processes, redirected streams, and pipes |

[Build, test, linking, and packaging guide](docs/building.md).
