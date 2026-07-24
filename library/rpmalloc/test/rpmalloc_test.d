import core.stdc.stdlib : EXIT_FAILURE, EXIT_SUCCESS;
import core.stdc.stddef : size_t;
import laserd.rpmalloc;

extern(C) int main()
{
    if (rpmalloc_initialize(null) != 0)
        return EXIT_FAILURE;

    void* allocation = rpmalloc(64);
    if (allocation is null || rpmalloc_usable_size(allocation) < 64)
        return EXIT_FAILURE;

    allocation = rprealloc(allocation, 256);
    if (allocation is null || rpmalloc_usable_size(allocation) < 256)
        return EXIT_FAILURE;
    rpfree(allocation);

    void* aligned_allocation = rpaligned_alloc(64, 128);
    if (aligned_allocation is null ||
        (cast(size_t) aligned_allocation & 63) != 0)
        return EXIT_FAILURE;
    rpfree(aligned_allocation);

    rpmalloc_heap_t* heap = rpmalloc_heap_acquire();
    if (heap is null)
        return EXIT_FAILURE;

    void* heap_allocation = rpmalloc_heap_alloc(heap, 96);
    if (heap_allocation is null ||
        rpmalloc_get_heap_for_ptr(heap_allocation) !is heap)
        return EXIT_FAILURE;

    heap_allocation = rpmalloc_heap_realloc(
        heap, heap_allocation, 192, 0);
    if (heap_allocation is null)
        return EXIT_FAILURE;

    void* zeroed = rpmalloc_heap_calloc(heap, 8, int.sizeof);
    if (zeroed is null)
        return EXIT_FAILURE;
    int* values = cast(int*) zeroed;
    foreach (size_t index; 0 .. 8)
        if (values[index] != 0)
            return EXIT_FAILURE;

    rpmalloc_heap_free(heap, heap_allocation);
    rpmalloc_heap_free_all(heap);
    rpmalloc_heap_release(heap);

    rpmalloc_finalize();
    return EXIT_SUCCESS;
}
