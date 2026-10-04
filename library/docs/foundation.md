# Foundation codecs, hashing, and lifecycle

Sources: `library/foundation_lib/laserd/foundation/*.d`. Link
`laserd_foundation`, `laserd_rpmalloc`, and the platform dependencies described
in [building](building.md).

The supported Foundation modules are the allocation-free Base64/hash bindings
and the explicit lifecycle adapter. [Threads](thread.md) and
[processes/streams](system.md) have separate purpose-oriented facades. Other
upstream Foundation APIs are not automatically supported: allocating MD5/SHA,
containers, filesystem, and callback-heavy APIs require separate review.
Foundation's mutex, semaphore, and beacon APIs remain private; public
synchronization uses nsync through `laserd.thread`.

## laserd.foundation.base64

No types or structs are added. Both APIs write to caller-owned buffers and
require no Foundation initialization. Encoding returns a count including the
trailing zero; decoding returns the decoded byte count. Supply sufficient output
capacity and use the returned count. Functions do not allocate the destination.

```d
extern(C) size_t base64_encode(
    const(void)* source,
    size_t size,
    char* destination,
    size_t capacity);
extern(C) size_t base64_decode(
    const(char)* source,
    size_t size,
    void* destination,
    size_t capacity);
size_t encode(const(ubyte)[] source, char[] destination);
size_t decode(const(char)[] source, ubyte[] destination);
```

## laserd.foundation.hash

`alias hash_t = uint64_t` is the 64-bit Murmur3 hash result type. These functions
are stateless and allocation-free; they require no Foundation initialization.
`hashBytes` takes a slice; `hash` takes a raw pointer and byte length.

```d
extern(C) hash_t hash(const(void)* key, size_t length);
hash_t hashBytes(const(ubyte)[] value);
```

## laserd.foundation.lifecycle

No structs or type aliases are added. `initialize` returns zero on success;
`isInitialized` reports whether the adapter is active. `finalize` releases the
process-wide lifecycle after all dependent resources and workers are finished.
The raw C adapter names are public alongside the D wrappers.

```d
extern(C) int laserd_foundation_initialize_rpmalloc();
extern(C) void laserd_foundation_finalize();
extern(C) int laserd_foundation_is_initialized();
int initialize();
void finalize();
bool isInitialized();
```

`laserd.foundation.lifecycle` initializes Foundation with rpmalloc through a
native adapter. Foundation owns the process-wide rpmalloc lifecycle between
`initialize` and `finalize`; an application must not independently initialize
or finalize rpmalloc during that interval. Foundation-created threads invoke
rpmalloc's per-thread initialization and finalization callbacks. Initialization
and finalization are idempotent.

Integration coverage: `library/test/foundation.d` (CTest `foundation_interop`), plus the thread and process integration programs.
