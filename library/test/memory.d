import core.stdc.stddef : size_t;
import core.stdc.stdlib :
    EXIT_FAILURE, EXIT_SUCCESS;
import core.stdc.stdio : puts;
import laserd.memory : Arena, Arena_create_rpmalloc, Arena_create_fixedregion, Arena_destroy;
import laserd.rpmalloc : finalize, initialize;


private int test_memory(Arena *arena)
{
    if (arena is null)
        return EXIT_FAILURE;
    scope(exit) { Arena_destroy(arena); }

    int* zeroed = cast(int*) arena.alloc(4 * int.sizeof);
    if (zeroed is null)
        return EXIT_FAILURE;
    foreach (size_t index; 0 .. 4)
        if (zeroed[index] != 0)
            return EXIT_FAILURE;
    foreach (size_t index; 0 .. 4)
        zeroed[index] = cast(int)(index + 1);

    void* rawExpanded = arena.realloc(
        zeroed,
        8 * int.sizeof,
        4 * int.sizeof);
    if (rawExpanded is null)
    {
        arena.free(zeroed);
        return EXIT_FAILURE;
    }
    zeroed = cast(int*) rawExpanded;

    foreach (size_t index; 0 .. 4)
        if (zeroed[index] != cast(int)(index + 1))
            return EXIT_FAILURE;
    foreach (size_t index; 4 .. 8)
        if (zeroed[index] != 0)
            return EXIT_FAILURE;
    arena.free(zeroed);

    int *one = arena.alloc!int();
    if (one is null)
        return EXIT_FAILURE;
    scope(exit) { arena.free(one); }

    int[] ary = arena.allocArray!int(2);
    if (ary.length != 2)
        return EXIT_FAILURE;
    scope(exit) arena.freeArray!int(ary);

    foreach (int index; 0 .. 2)
        ary[index] = index+1;
    int[] expanded = arena.expandArray!int(ary, 4);
    if (expanded is null)
        return EXIT_FAILURE;
    ary = expanded;
    if (ary.length != 4)
        return EXIT_FAILURE;

    foreach (int index; 0 .. 2)
        if (ary[index] != index+1)
            return EXIT_FAILURE;
    foreach (int index; 2 .. 4)
        if (ary[index] != 0)
            return EXIT_FAILURE;

    int[] empty = arena.allocArray!int(0);
    if (empty.ptr !is null || empty.length != 0)
        return EXIT_FAILURE;

    int[] overflow = arena.expandArray!int(ary, size_t.max);
    if (overflow !is null)
        return EXIT_FAILURE;

    // Original allocation must remain valid after failed expansion.
    if (ary[0] != 1 || ary[1] != 2)
        return EXIT_FAILURE;

    return EXIT_SUCCESS;
}

private int test_fixedregion_boundaries()
{
    Arena *arena = Arena_create_fixedregion(512);
    if (arena is null)
        return EXIT_FAILURE;
    scope(exit) Arena_destroy(arena);

    void *aligned = arena.aligned_alloc(256, 1);
    if (aligned is null || (cast(size_t) aligned & 255) != 0)
        return EXIT_FAILURE;

    if (arena.aligned_alloc(8, 0) !is null)
        return EXIT_FAILURE;

    if (arena.aligned_calloc(8, size_t.max / 8 + 1, 8) !is null)
        return EXIT_FAILURE;

    Arena *small = Arena_create_fixedregion(16);
    if (small is null)
        return EXIT_FAILURE;
    scope(exit) Arena_destroy(small);

    if (small.alloc(16) is null)
        return EXIT_FAILURE;
    if (small.alloc(1) !is null)
        return EXIT_FAILURE;

    Arena_destroy(null);
    return EXIT_SUCCESS;
}

extern(C) int main()
{
    if (initialize(null) != 0)
        return EXIT_FAILURE;
    scope(exit) finalize();
    
    puts("testing rpmalloc\n");
    int rc = test_memory(Arena_create_rpmalloc());
    if (rc == EXIT_FAILURE) return rc;
    puts("testing fixedregion arena\n");
    rc = test_memory(Arena_create_fixedregion(512));
    if (rc == EXIT_FAILURE) return rc;
    rc = test_fixedregion_boundaries();
    return rc;
}
