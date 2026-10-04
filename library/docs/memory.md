# Arena allocation: laserd.memory

`laserd.memory` provides explicit allocation through `Arena`. Choose a general
allocator, a bounded fixed-region allocator, or a bump allocator with bulk
reclamation. Create and destroy each arena explicitly.

Allocations are zero-filled. Successful growth preserves existing bytes and
zeroes newly exposed bytes; failure leaves the original allocation valid.
Free or expand storage through the arena that allocated it, using the complete
returned allocation rather than a subslice.

## Arena

`Arena` is the allocation type used by callers. Create an `Arena*` with one of
the factory functions below. `DEFAULT_ALIGNMENT` is `(void*).sizeof`.

## Creation and destruction

```d
Arena* Arena_create_rpmalloc();
Arena* Arena_create_fixedregion(size_t fixed_region_size);
Arena* Arena_create_bump();
void Arena_destroy(Arena* arena);
```

Factories return null on allocation failure. `Arena_destroy(null)` does nothing.
Destruction invalidates the arena pointer and any remaining region-backed
storage. For an rpmalloc arena, free each allocation before destroying the arena.
Fixed-region and bump arenas retain freed storage until arena destruction.
Do not copy arena ownership or use
an arena after destruction.

Serialize access to fixed-region and bump arenas. Using an arena does not
relax its allocator's thread-safety or thread-initialization requirements.

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

## Using the library

Link `laserd_rpmalloc` and its platform
dependencies; see [building](building.md). Initialize rpmalloc directly or
through [Foundation](foundation.md) before creating an arena.

## Implementation Details

Source: `library/laserd/memory.d`.

Integration coverage: `library/test/memory.d` (CTest `memory_facade`).

### Backend records and callbacks

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
```

`Arena` dispatches through a private context and callback table. The rpmalloc
backend does not track individual allocations. Fixed-region and bump backends
do not reclaim individual frees and have no internal synchronization.

The fixed-region backend owns one bounded region. The bump backend lazily
allocates a list of 8 KiB fixed regions and uses dedicated regions for larger
requests; destroying it releases all regions.
