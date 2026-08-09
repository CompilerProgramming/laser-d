module laserd.memory;

import core.stdc.stddef;
import core.stdc.string : memset;
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

private struct Arena_FunctionTable
{
    AllocFn allocImpl;
    CallocFn callocImpl;
    ReallocFn reallocImpl;
    AlignedAllocFn alignedAllocImpl;
    AlignedCallocFn alignedCallocImpl;
    AlignedReallocFn alignedReallocImpl;    
    FreeFn freeImpl;
}

private void *rpmalloc_alloc(void *ctx, size_t size)
{
    return zeroAllocate(size);
}
private void *rpmalloc_calloc(void *ctx, size_t count, size_t size)
{
    return allocateArray(count, size);
}
private void zeroReallocatedTail(void *pointer, size_t size, size_t oldSize)
{
    if (pointer !is null && size > oldSize)
        memset(cast(ubyte*) pointer + oldSize, 0, size - oldSize);
}
private void *rpmalloc_realloc(
    void *ctx, void *pointer, size_t size, size_t oldSize)
{
    void *result = reallocate(pointer, size);
    zeroReallocatedTail(result, size, oldSize);
    return result;
}
private void *rpmalloc_aligned_alloc(void *ctx, size_t alignment, size_t size)
{
    if (alignment < (void*).sizeof)
        alignment = (void*).sizeof;
    return alignedZeroAllocate(alignment, size);
}
private void *rpmalloc_aligned_calloc(void *ctx, size_t alignment, size_t count, size_t size)
{
    if (alignment < (void*).sizeof)
        alignment = (void*).sizeof;
    return alignedAllocateArray(alignment, count, size);
}
private void *rpmalloc_aligned_realloc(void *ctx, void* pointer, size_t alignment, size_t size, size_t old_size)
{
    if (alignment < (void*).sizeof)
        alignment = (void*).sizeof;
    void *result = alignedReallocate(pointer, alignment, size, old_size, 0);
    zeroReallocatedTail(result, size, old_size);
    return result;
}
private void rpmalloc_free(void *ctx, void *pointer)
{
    return rpfree(pointer);
}

private immutable Arena_FunctionTable rpmalloc_function_table = 
    Arena_FunctionTable(
        &rpmalloc_alloc,
        &rpmalloc_calloc,
        &rpmalloc_realloc,
        &rpmalloc_aligned_alloc,
        &rpmalloc_aligned_calloc,
        &rpmalloc_aligned_realloc,
        &rpmalloc_free);

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

Arena* Arena_create()
{
    Arena *arena = cast(Arena*) zeroAllocate(Arena.sizeof);
    if (arena is null)
        return null;
    arena.vtable = &rpmalloc_function_table;
    return arena;
}

void Arena_destroy(Arena *arena)
{
    rpfree(arena);
}


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

FixedRegionAllocator *FixedRegionAllocator_create(size_t size)
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

void FixedRegionAllocator_destroy(FixedRegionAllocator *allocator)
{
    if (allocator is null)
        return;
    rpfree(allocator.memory.ptr);
    rpfree(allocator);
}

private void *fixed_region_allocate(void *ctx, size_t alignment, size_t alloc_size)
{
    if (ctx is null) return null;
    FixedRegionAllocator *allocator = cast(FixedRegionAllocator *)ctx;

    if (alloc_size == 0) return null;
    if (alignment == 0) alignment = DEFAULT_ALIGNMENT;
    // get aligned offset
    auto offset = (allocator.offset + alignment - 1u) & ~(alignment - 1u);
    // do we have enough room?
    auto remaining = allocator.memory.length - offset;
    if (remaining < alloc_size)
        return null;
    void *ptr = cast(void *) &allocator.memory.ptr[offset];
    allocator.offset = offset + alloc_size;
    return ptr;
}

