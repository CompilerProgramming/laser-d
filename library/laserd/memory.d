module laserd.memory;

import core.stdc.stddef;
import core.stdc.string : memset, memcpy;
import laserd.rpmalloc :
    zeroAllocate, allocateArray, reallocate,
    alignedZeroAllocate, alignedAllocateArray, alignedReallocate,
    rpfree = free;
    

alias AllocFn = void *function(void *ctx, size_t size);
alias CallocFn = void *function(void *ctx, size_t count, size_t size);
alias ReallocFn = void *function(
    void *ctx, void *pointer, size_t size, size_t oldSize);
alias AlignedAllocFn = void *function(void *ctx, size_t alignment, size_t size);
alias AlignedCallocFn = void* function(void *ctx, size_t alignment, size_t count, size_t size);
alias AlignedReallocFn = void* function(void *ctx, void* pointer, size_t alignment, size_t size, size_t old_size);
alias FreeFn = void function(void *ctx, void *pointer);
alias DestroyFn = void function(void *ctx);

private struct Arena_FunctionTable
{
    AllocFn allocImpl;
    CallocFn callocImpl;
    ReallocFn reallocImpl;
    AlignedAllocFn alignedAllocImpl;
    AlignedCallocFn alignedCallocImpl;
    AlignedReallocFn alignedReallocImpl;    
    FreeFn freeImpl;
    DestroyFn destroyImpl;
}

private void *arena_rpmalloc_alloc(void *ctx, size_t size)
{
    return zeroAllocate(size);
}
private void *arena_rpmalloc_calloc(void *ctx, size_t count, size_t size)
{
    return allocateArray(count, size);
}
private void zero_reallocated_tail(void *pointer, size_t size, size_t oldSize)
{
    if (pointer !is null && size > oldSize)
        memset(cast(ubyte*) pointer + oldSize, 0, size - oldSize);
}
private void *arena_rpmalloc_realloc(
    void *ctx, void *pointer, size_t size, size_t oldSize)
{
    void *result = reallocate(pointer, size);
    zero_reallocated_tail(result, size, oldSize);
    return result;
}
private void *arena_rpmalloc_aligned_alloc(void *ctx, size_t alignment, size_t size)
{
    if (alignment < (void*).sizeof)
        alignment = (void*).sizeof;
    return alignedZeroAllocate(alignment, size);
}
private void *arena_rpmalloc_aligned_calloc(void *ctx, size_t alignment, size_t count, size_t size)
{
    if (alignment < (void*).sizeof)
        alignment = (void*).sizeof;
    return alignedAllocateArray(alignment, count, size);
}
private void *arena_rpmalloc_aligned_realloc(void *ctx, void* pointer, size_t alignment, size_t size, size_t old_size)
{
    if (alignment < (void*).sizeof)
        alignment = (void*).sizeof;
    void *result = alignedReallocate(pointer, alignment, size, old_size, 0);
    zero_reallocated_tail(result, size, old_size);
    return result;
}
private void arena_rpmalloc_free(void *ctx, void *pointer)
{
    return rpfree(pointer);
}
private void arena_rpmalloc_destroy(void *ctx)
{
}

private immutable Arena_FunctionTable rpmalloc_function_table = 
    Arena_FunctionTable(
        &arena_rpmalloc_alloc,
        &arena_rpmalloc_calloc,
        &arena_rpmalloc_realloc,
        &arena_rpmalloc_aligned_alloc,
        &arena_rpmalloc_aligned_calloc,
        &arena_rpmalloc_aligned_realloc,
        &arena_rpmalloc_free,
        &arena_rpmalloc_destroy);

private immutable Arena_FunctionTable fixedregion_function_table = 
    Arena_FunctionTable(
      &fixed_region_alloc,
      &fixed_region_calloc,
      &fixed_region_realloc,
      &fixed_region_aligned_alloc,
      &fixed_region_aligned_calloc,
      &fixed_region_aligned_realloc,
      &fixed_region_free,
      &fixed_region_arena_destroy
    );

struct Arena
{
    public:

    void* alloc(size_t size) 
    {
        if (vtable is null) return null;
        return vtable.allocImpl(ctx, size);
    }
    void* calloc(size_t count, size_t size)
    {
        if (vtable is null) return null;
        return vtable.callocImpl(ctx, count, size);
    }
    void* realloc(void* pointer, size_t size, size_t oldSize)
    {
        if (vtable is null) return null;
        return vtable.reallocImpl(ctx, pointer, size, oldSize);
    }
    void *aligned_alloc(size_t alignment, size_t size)
    {
        if (vtable is null) return null;
        return vtable.alignedAllocImpl(ctx, alignment, size);
    }
    void *aligned_calloc(size_t alignment, size_t count, size_t size)
    {
        if (vtable is null) return null;
        return vtable.alignedCallocImpl(ctx, alignment, count, size);
    }
    void *aligned_realloc(void* pointer, size_t alignment, size_t size, size_t old_size)
    {
        if (vtable is null) return null;
        return vtable.alignedReallocImpl(ctx, pointer, alignment, size, old_size);
    }
    void free(void* pointer)
    {
        if (vtable !is null)
            vtable.freeImpl(ctx, pointer);
    }

    T *alloc(T)()
    {
        return cast(T*) aligned_alloc(T.alignof, T.sizeof);
    }
    T[] allocArray(T)(size_t count)
    {
        if (count == 0)
            return null;
        if (count > size_t.max / T.sizeof)
            return null;
        T* values = cast(T*) aligned_calloc(T.alignof, count, T.sizeof);
        if (values is null)
            return null;
        return values[0..count];
    }
    T[] expandArray(T)(T[] original, size_t newCount)
    {
        if (newCount <= original.length)
            return original;

        if (newCount > size_t.max / T.sizeof)
            return null;

        size_t oldSize = original.length * T.sizeof;
        size_t newSize = newCount * T.sizeof;

        T* expanded = cast(T*) aligned_realloc(
            original.ptr,
            T.alignof,
            newSize,
            oldSize);

        if (expanded is null)
            return null;

        return expanded[0 .. newCount];
    }
    void freeArray(T)(T[] ary)
    {
        if (ary.ptr !is null)
            free(ary.ptr);
    }
    private:

    void *ctx;
    immutable(Arena_FunctionTable) *vtable;
}

Arena* Arena_create_rpmalloc()
{
    Arena *arena = cast(Arena*) zeroAllocate(Arena.sizeof);
    if (arena is null)
        return null;
    arena.vtable = &rpmalloc_function_table;
    return arena;
}

Arena* Arena_create_fixedregion(size_t fixed_region_size)
{
    Arena *arena = cast(Arena*) zeroAllocate(Arena.sizeof);
    if (arena is null)
        return null;
    arena.vtable = &fixedregion_function_table;
    arena.ctx = fixed_region_arena_create(fixed_region_size);
    return arena;
}

void Arena_destroy(Arena *arena)
{
    if (arena.vtable)
        arena.vtable.destroyImpl(arena.ctx);
    rpfree(arena);
}

// This allocator is a simple bump allocator that
// uses a fixed size region. All allocations happen
// from the end of the region until exhausted
struct FixedRegionAllocator
{
    byte[] memory;  // buffer to use for memory allocations
	size_t offset; // Current position up to which memory is allocated
    FixedRegionAllocator *next; // for chaining
}

private union Value
{
    void *ptr;
    double d;
    long l;
}

enum DEFAULT_ALIGNMENT = Value.alignof;

private FixedRegionAllocator *fixed_region_arena_create(size_t size)
{
    FixedRegionAllocator *allocator;

    allocator = cast(FixedRegionAllocator *) zeroAllocate(FixedRegionAllocator.sizeof);
    if (allocator is null)
        return null;
    byte *memory = cast(byte *) zeroAllocate(size);
    if (memory is null) 
    {
        rpfree(allocator);
        return null;
    }
    allocator.memory = memory[0..size];
    allocator.offset = 0;
    allocator.next = null;

    return allocator;
}

private void fixed_region_arena_destroy(void *ctx)
{
    FixedRegionAllocator *allocator = cast(FixedRegionAllocator *)ctx;
    if (allocator is null)
        return;
    rpfree(allocator.memory.ptr);
    rpfree(allocator);
}

private void *fixed_region_aligned_alloc(void *ctx, size_t alignment, size_t alloc_size)
{
    if (ctx is null) return null;
    FixedRegionAllocator *allocator = cast(FixedRegionAllocator *)ctx;

    assert((alignment == 0) || (alignment & (alignment - 1)) == 0); // assert alignment is power of two
    if (alloc_size == 0) return null;
    if (alignment == 0) alignment = DEFAULT_ALIGNMENT;
    // get aligned offset
    auto offset = (allocator.offset + alignment - 1u) & ~(alignment - 1u);
    // do we have enough room?
    if (offset > allocator.memory.length)
        return null;
    auto remaining = allocator.memory.length - offset;
    if (remaining < alloc_size)
        return null;
    void *ptr = cast(void *) &allocator.memory.ptr[offset];
    allocator.offset = offset + alloc_size;
    return ptr;
}

private void *fixed_region_aligned_calloc(void *ctx, size_t alignment, size_t count, size_t object_size)
{
    // Every array element must begin at an address satisfying `alignment`.
    assert(alignment == 0 || (object_size % alignment) == 0);
    return fixed_region_aligned_alloc(ctx, alignment, count * object_size);
}

private void *fixed_region_aligned_realloc(void *ctx, void* pointer, size_t alignment, size_t alloc_size, size_t old_size)
{
    if (ctx is null) return null;
    FixedRegionAllocator *allocator = cast(FixedRegionAllocator *)ctx;

    if (alloc_size == 0) return null;
    if (alloc_size < old_size) return pointer;
    auto new_pointer = fixed_region_aligned_alloc(ctx, alignment, alloc_size);
    if (new_pointer == null) return null;
    memcpy(new_pointer, pointer, old_size);
    // No need to zero tail as its region is already zeroed
    return new_pointer;
}

private void *fixed_region_alloc(void *ctx, size_t size)
{
    return fixed_region_aligned_alloc(ctx, 0, size);
}
private void *fixed_region_calloc(void *ctx, size_t count, size_t object_size)
{
    return fixed_region_aligned_alloc(ctx, 0, count * object_size);
}
private void *fixed_region_realloc(void *ctx, void* pointer, size_t alloc_size, size_t old_size)
{
    return fixed_region_aligned_realloc(ctx, pointer, 0, alloc_size, old_size);
}
private void fixed_region_free(void *ctx, void *pointer)
{
}
