---
title: Garbage collection
status: rejected
source: ../spec/garbage.dd
---

# Memory Management

> **Laser-D normative:**
>
> Laser-D has no garbage collector and no D runtime memory
> manager. The language does not implicitly allocate, trace, retain, resize, or
> free program storage. Storage duration and ownership must be visible in the
> program or defined by an explicitly called foreign API.

## <a id="storage"></a>Supported Storage

Laser-D programs may use:

- automatic local variables and fixed-size arrays,
- fields and inline fixed-size arrays within supported structs and unions,
- immutable data in static storage, including string-literal backing storage,
- caller-provided storage accessed through pointers or non-owning slices,
- storage returned by an explicitly declared C or other supported foreign function.

Mutable D-owned global and static storage is rejected by the separate
global-state rules. ImportC retains the C storage model.

## <a id="slices"></a>Slices Are Non-Owning Views

A dynamic-array type `T[]` is supported only as a pointer-and-length
view. A slice does not own its elements, keep their storage alive, record a
capacity, or arrange for deallocation. Copying a slice copies only the view.

The programmer must ensure that a slice is not used after its backing
storage expires or is released. Returning a slice into automatic local storage
is invalid even though no garbage collector is involved.

## <a id="excluded"></a>Excluded Implicit Allocation

> **Excluded from Laser-D:**
>
> The following D facilities are not part of Laser-D because
> they allocate implicitly or depend on garbage-collector metadata:

- every `new` expression, including placement and array forms,
- dynamic-array and associative-array literals,
- associative-array types and operations,
- built-in array concatenation with `~` or `~=`,
- `.dup`, `.idup`, and `.capacity`,
- appending to an array and assigning to a dynamic-array `.length`,
- closure capture and hidden heap-allocated delegate contexts,
- `__traits(getPointerBitmap)` and other GC scanning metadata.

String literals are not dynamic-array allocations. Their immutable backing
storage is supplied by the compiled program, and the resulting slice remains a
non-owning view.

## <a id="explicit-allocation"></a>Explicit Allocation

A program may call an explicitly declared foreign allocator such as a C
runtime or platform API. Such a call is an ordinary visible function call; it
is not a Laser-D language allocation facility.

```d
extern(C) void* malloc(size_t size);
extern(C) void free(void* address);

void useStorage()
{
    void* storage = malloc(256);
    if (storage is null)
    {
        // handle allocation failure
        return;
    }
    scope(exit) free(storage);

    // use storage
}
```

The allocator's contract determines alignment, lifetime, failure handling, threading behavior, and the matching release operation. Laser-D does not add
ownership tracking or automatically call `free`. A pointer or slice derived
from released storage becomes invalid.

## <a id="cleanup"></a>Cleanup and Resource Ownership

Cleanup is explicit. Programs may use ordinary control flow and
`scope(exit)` to ensure that a visible release function is called.
Struct destructors, class finalizers, exceptions, and garbage-collector finalizers
are unavailable.

A program must define who owns allocated storage, when ownership transfers, and which operation releases it. The compiler does not diagnose leaks, double-release errors, dangling pointers, or use after release.

## <a id="interoperability"></a>Interoperability

Pointers may cross a supported foreign-function boundary according to that
API's ABI and ownership contract. A Laser-D slice passed to foreign code is
represented by its pointer and length only when the declared interface
explicitly uses that representation; it is not implicitly a C array or an
owning foreign container.
