# Arena allocation: laserd.memory

Source: `library/laserd/memory.d`. Link `laserd_rpmalloc` and its platform
dependencies; see [building](building.md). Initialize rpmalloc directly or
through [Foundation](foundation.md) before creating an arena.

The `laserd.memory` module provides the higher-level `Arena` facade. An arena is
created and destroyed explicitly and selects a private backend callback table.
Raw and typed allocation return zeroed storage, and typed arrays reject
byte-size overflow. Reallocation receives the allocation's logical old size;
successful growth preserves existing bytes and zeroes the newly exposed range,
while failure leaves the original allocation valid. Memory must be expanded or
freed through the arena which allocated it, using the complete returned slice
rather than a subslice. The fixed-region backend owns one bounded region. The
bump backend lazily owns a list of 8 KiB fixed regions, uses dedicated regions
for larger requests, does not reclaim individual allocations, and releases all
regions on destruction.

## Types

| Type | Purpose |
| --- | --- |
| `Arena` | Public allocation facade with private context and backend table; use an `Arena*` returned by a factory. |
| `FixedRegionAllocator` | Backend storage record with `byte[] memory`, `size_t offset`, and `FixedRegionAllocator* next`; applications normally use the arena factory. |
| `BumpAllocator` | Backend record with private region pointers. |

The module also declares callback aliases. The dispatch table itself is private;
these aliases do not provide a public custom-backend constructor.

```d
alias AllocFn = void *function(void *ctx, size_t size);
alias CallocFn = void *function(void *ctx, size_t count, size_t size);
alias ReallocFn = void *function(
    void *ctx, void *pointer, size_t size, size_t oldSize);
alias AlignedAllocFn = void *function(void *ctx, size_t alignment, size_t size);
alias AlignedCallocFn = void* function(void *ctx, size_t alignment, size_t count, size_t size);
alias AlignedReallocFn = void* function(void *ctx, void* pointer, size_t alignment, size_t size, size_t old_size);
alias FreeFn = void function(void *ctx, void *pointer);
alias DestroyFn = void function(void *ctx);

enum DEFAULT_ALIGNMENT = (void*).sizeof;
```

## Creation and destruction

```d
Arena* Arena_create_rpmalloc();
Arena* Arena_create_fixedregion(size_t fixed_region_size);
Arena* Arena_create_bump();
void Arena_destroy(Arena* arena);
```

Factories return null on allocation failure. `Arena_destroy(null)` does nothing.
Destruction invalidates the arena pointer and any remaining region-backed
storage. The rpmalloc backend does not track its individual allocations;
free those before destroying its facade. Fixed-region and bump backends retain
individual frees until arena destruction. Do not copy arena ownership or use
an arena after destruction.

Fixed-region and bump mutation has no internal synchronization. Keep access
serialized; the Arena facade does not add synchronization to any backend.
Direct rpmalloc use retains rpmalloc's thread initialization requirements.

## Arena methods

```d
void* alloc(size_t size);
void* calloc(size_t count, size_t size);
void* realloc(void* pointer, size_t size, size_t oldSize);
void* aligned_alloc(size_t alignment, size_t size);
void* aligned_calloc(size_t alignment, size_t count, size_t size);
void* aligned_realloc(void* pointer, size_t alignment, size_t size, size_t old_size);
void free(void* pointer);
T* alloc(T)();
T[] allocArray(T)(size_t count);
T[] expandArray(T)(T[] original, size_t newCount);
void freeArray(T)(T[] ary);
```

Sizes are bytes for raw allocation and elements for typed arrays. Allocation is
zero-filled, not initialized using each type's `T.init`. Alignment must be zero
(selecting `DEFAULT_ALIGNMENT`) or a power of two. `aligned_calloc` also requires
an element size divisible by the nonzero requested alignment.

For reallocation supply the logical old byte size, not allocator capacity;
use zero for a null pointer. Failure returns null and preserves the original
allocation. `expandArray` never shrinks: a count no larger than the existing
length returns the original slice. Empty or overflowing `allocArray` requests
return null. Always free or expand through the same arena using the complete
allocation, not a subslice. Reclamation remains backend-specific.

Integration coverage: `library/test/memory.d` (CTest `memory_facade`).
