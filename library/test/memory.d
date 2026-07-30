import core.stdc.stddef : size_t;
import core.stdc.stdlib :
    EXIT_FAILURE, EXIT_SUCCESS,
    cAllocate = malloc,
    cAllocateArray = calloc,
    cReallocate = realloc,
    cFree = free;
import laserd.memory : Arena;
import laserd.rpmalloc : finalize, initialize;

private void* customAllocate(void*, size_t size)
{
    return cAllocate(size);
}

private void* customAllocateArray(void*, size_t count, size_t size)
{
    return cAllocateArray(count, size);
}

private void* customReallocate(void*, void* pointer, size_t size)
{
    return cReallocate(pointer, size);
}

private void customFree(void*, void* pointer)
{
    cFree(pointer);
}

extern(C) int main()
{
    if (initialize(null) != 0)
        return EXIT_FAILURE;

    Arena defaultArena;
    int* zeroed = cast(int*) defaultArena.alloc(4 * int.sizeof);
    if (zeroed is null)
        return EXIT_FAILURE;
    foreach (size_t index; 0 .. 4)
        if (zeroed[index] != 0)
            return EXIT_FAILURE;
    defaultArena.free(zeroed);

    Arena customArena = Arena(
        null,
        &customAllocate,
        &customAllocateArray,
        &customReallocate,
        &customFree);
    void* allocation = customArena.alloc(32);
    if (allocation is null)
        return EXIT_FAILURE;
    allocation = customArena.realloc(allocation, 64);
    if (allocation is null)
        return EXIT_FAILURE;
    customArena.free(allocation);

    int* customZeroed = cast(int*) customArena.calloc(4, int.sizeof);
    if (customZeroed is null)
        return EXIT_FAILURE;
    foreach (size_t index; 0 .. 4)
        if (customZeroed[index] != 0)
            return EXIT_FAILURE;
    customArena.free(customZeroed);

    finalize();
    return EXIT_SUCCESS;
}
