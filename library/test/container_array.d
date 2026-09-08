import core.stdc.stdlib : EXIT_FAILURE, EXIT_SUCCESS;
import core.stdc.stddef : size_t;
import laserd.memory : Arena, Arena_create_bump, Arena_create_fixedregion,
    Arena_create_rpmalloc, Arena_destroy;
import laserd.array : Array;

private int testArray(Arena* arena)
{
    int[3] initial = [0, 2, 3];
    auto values = Array!int(arena, initial[]);
    if (values.length() != 3 || values.capacity() != 3)
        return EXIT_FAILURE;
    if (values[0] != 0 || values.front() != 0 || values.back() != 3)
        return EXIT_FAILURE;
    if (!values.reserve(1000) || values.length() != 3 || values.capacity() < 1000)
        return EXIT_FAILURE;
    if (values.insertBefore(values[1 .. $], 1) != 1)
        return EXIT_FAILURE;
    if (values.length() != 4 || values[1] != 1)
        return EXIT_FAILURE;
    values ~= 4;
    if (values.length() != 5 || values.back() != 4)
        return EXIT_FAILURE;
    values[1] = values[1] * 42;
    if (values[1] != 42)
        return EXIT_FAILURE;
    auto copy = values;
    copy[0] = 9;
    if (values[0] != 9)
        return EXIT_FAILURE;
    auto duplicate = values.dup();
    duplicate[0] = 7;
    if (values[0] != 9 || duplicate[0] != 7)
        return EXIT_FAILURE;
    auto range = values[1 .. 3];
    if (range.length() != 2 || range.front() != 42 || range.back() != 2)
        return EXIT_FAILURE;
    range.popFront();
    if (range.length() != 1 || range.front() != 2)
        return EXIT_FAILURE;
    values.linearRemove(values[1 .. 3]);
    if (values.length() != 3 || values[0] != 9 || values[1] != 3 || values[2] != 4)
        return EXIT_FAILURE;
    if (values.removeBack(2) != 2 || values.length() != 1 || values.back() != 9)
        return EXIT_FAILURE;
    if (!values.resize(4) || values.length() != 4 || values[1] != 0)
        return EXIT_FAILURE;
    values[] = 6;
    if (values[0] != 6 || values[3] != 6)
        return EXIT_FAILURE;
    if (values.insertBack(values.data()) != 4 || values.length() != 8
        || values[4] != 6 || values[7] != 6)
        return EXIT_FAILURE;
    copy.clear();
    if (!values.empty() || values.capacity() != 0 || !copy.empty())
        return EXIT_FAILURE;
    duplicate.destroy();
    values.destroy();
    return EXIT_SUCCESS;
}

private int testFailurePreservesArray()
{
    Arena* arena = Arena_create_fixedregion(128);
    if (arena is null)
        return EXIT_FAILURE;
    auto values = Array!int(arena);
    if (values.insertBack(17) != 1)
        return EXIT_FAILURE;
    size_t oldCapacity = values.capacity();
    if (values.reserve(size_t.max))
        return EXIT_FAILURE;
    if (values.length() != 1 || values[0] != 17 || values.capacity() != oldCapacity)
        return EXIT_FAILURE;
    values.destroy();
    Arena_destroy(arena);
    return EXIT_SUCCESS;
}

extern(C) int main()
{
    Arena* arena = Arena_create_rpmalloc();
    if (arena is null)
        return EXIT_FAILURE;
    int result = testArray(arena);
    Arena_destroy(arena);
    if (result != EXIT_SUCCESS)
        return result;

    Arena* bump = Arena_create_bump();
    if (bump is null)
        return EXIT_FAILURE;
    result = testArray(bump);
    Arena_destroy(bump);
    if (result != EXIT_SUCCESS)
        return result;

    return testFailurePreservesArray();
}
