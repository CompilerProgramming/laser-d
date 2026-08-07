import core.stdc.stddef : size_t;
import core.stdc.stdlib :
    EXIT_FAILURE, EXIT_SUCCESS;
import laserd.memory : Arena, Arena_create, Arena_destroy;
import laserd.rpmalloc : finalize, initialize;


extern(C) int main()
{
    if (initialize(null) != 0)
        return EXIT_FAILURE;
    scope(exit) finalize();

    Arena *arena = Arena_create();
    if (arena is null)
        return EXIT_FAILURE;
    scope(exit) { Arena_destroy(arena); }

    int* zeroed = cast(int*) arena.alloc(4 * int.sizeof);
    if (zeroed is null)
        return EXIT_FAILURE;
    foreach (size_t index; 0 .. 4)
        if (zeroed[index] != 0)
            return EXIT_FAILURE;
    arena.free(zeroed);

    return EXIT_SUCCESS;
}
