import core.stdc.stdlib : EXIT_FAILURE, EXIT_SUCCESS;
import core.stdc.stddef : size_t;
import laserd.memory;

extern(C) int main()
{
    if (initialize(null) != 0)
        return EXIT_FAILURE;

    void* allocation = allocate(64);
    if (allocation is null || usableSize(allocation) < 64)
        return EXIT_FAILURE;

    allocation = reallocate(allocation, 256);
    if (allocation is null || usableSize(allocation) < 256)
        return EXIT_FAILURE;
    free(allocation);

    void* aligned_allocation = alignedAllocate(64, 128);
    if (aligned_allocation is null ||
        (cast(size_t) aligned_allocation & 63) != 0)
        return EXIT_FAILURE;
    free(aligned_allocation);

    Heap* heap = acquireHeap();
    if (heap is null)
        return EXIT_FAILURE;

    void* heap_allocation = allocateFromHeap(heap, 96);
    if (heap_allocation is null ||
        heapForPointer(heap_allocation) !is heap)
        return EXIT_FAILURE;

    heap_allocation = reallocateFromHeap(
        heap, heap_allocation, 192, 0);
    if (heap_allocation is null)
        return EXIT_FAILURE;

    void* zeroed = allocateArrayFromHeap(heap, 8, int.sizeof);
    if (zeroed is null)
        return EXIT_FAILURE;
    int* values = cast(int*) zeroed;
    foreach (size_t index; 0 .. 8)
        if (values[index] != 0)
            return EXIT_FAILURE;

    freeFromHeap(heap, heap_allocation);
    freeAllFromHeap(heap);
    releaseHeap(heap);

    finalize();
    return EXIT_SUCCESS;
}
