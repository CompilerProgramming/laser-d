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
        // validation to be fixed when assertion is in place
        // to check that all are not null
    }

    void* alloc(size_t size) 
    {
        if (ctx)
            return allocImpl(ctx, size);
        return zeroAllocate(size);
    }

    void* calloc(size_t count, size_t size)
    {
        if (ctx)
            return callocImpl(ctx, count, size);
        return allocateArray(count, size);
    }
    void* realloc(void* pointer, size_t size)
    {
        if (ctx)
            return reallocImpl(ctx, pointer, size);
        return reallocate(pointer, size);
    }
    void free(void* pointer)
    {
        if (ctx)
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