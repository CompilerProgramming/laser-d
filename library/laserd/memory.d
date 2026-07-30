module laserd.memory;

import core.stdc.stddef;
import laserd.rpmalloc :
    zeroAllocate, allocateArray, reallocate,
    rpfree = free;
    

alias AllocFn = void *function(void *ctx, size_t size);
alias CallocFn = void *function(void *ctx, size_t count, size_t size);
alias ReallocFn = void *function(void *ctx, void *pointer, size_t size);
alias FreeFn = void function(void *ctx, void *pointer);


struct Arena
{
    public:

    this(void *ctx,
        AllocFn allocImpl,
        CallocFn callocImpl,
        ReallocFn reallocImpl,
        FreeFn freeImpl)
    {
        this.ctx = ctx;
        this.allocImpl = allocImpl;
        this.callocImpl = callocImpl;
        this.reallocImpl = reallocImpl;
        this.freeImpl = freeImpl;
        const allNull = allocImpl is null &&
            callocImpl is null &&
            reallocImpl is null &&
            freeImpl is null;
        const allPresent = allocImpl !is null &&
            callocImpl !is null &&
            reallocImpl !is null &&
            freeImpl !is null;
        assert(allNull || allPresent,
            "Arena allocator callbacks must be all null or all present");
    }

    void* alloc(size_t size) 
    {
        if (allocImpl !is null)
            return allocImpl(ctx, size);
        return zeroAllocate(size);
    }

    void* calloc(size_t count, size_t size)
    {
        if (callocImpl !is null)
            return callocImpl(ctx, count, size);
        return allocateArray(count, size);
    }
    void* realloc(void* pointer, size_t size)
    {
        if (reallocImpl !is null)
            return reallocImpl(ctx, pointer, size);
        return reallocate(pointer, size);
    }
    void free(void* pointer)
    {
        if (freeImpl !is null)
            return freeImpl(ctx, pointer);
        return rpfree(pointer);
    }

    private:

    void *ctx;

    AllocFn allocImpl;
    CallocFn callocImpl;
    ReallocFn reallocImpl;
    FreeFn freeImpl;
}
