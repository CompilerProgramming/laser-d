module laserd.memory;

import core.stdc.stddef;
import laserd.rpmalloc :
    zeroAllocate, allocateArray, reallocate,
    alignedZeroAllocate, alignedAllocateArray, alignedReallocate,
    rpfree = free;
    

alias AllocFn = void *function(void *ctx, size_t size);
alias CallocFn = void *function(void *ctx, size_t count, size_t size);
alias ReallocFn = void *function(void *ctx, void *pointer, size_t size);
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
private void *rpmalloc_realloc(void *ctx, void *pointer, size_t size)
{
    return reallocate(pointer, size);
}
private void *rpmalloc_aligned_alloc(void *ctx, size_t alignment, size_t size)
{
    return alignedZeroAllocate(alignment, size);
}
private void *rpmalloc_aligned_calloc(void *ctx, size_t alignment, size_t count, size_t size)
{
    return alignedAllocateArray(alignment, count, size);
}
private void *rpmalloc_aligned_realloc(void *ctx, void* pointer, size_t alignment, size_t size, size_t old_size)
{
    return alignedReallocate(pointer, alignment, size, old_size, 0);
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
    void* realloc(void* pointer, size_t size)
    {
        if (vtable is null) return null;
        return vtable.reallocImpl(ctx, pointer, size);
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
