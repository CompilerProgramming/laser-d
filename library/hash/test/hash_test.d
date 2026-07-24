import core.stdc.stddef : size_t;
import core.stdc.stdlib : EXIT_FAILURE, EXIT_SUCCESS;
import core.stdc.string : strcmp;
import laserd.hash;
import laserd.rpmalloc;

private int require(bool condition)
{
    return condition ? 0 : 1;
}

private extern(C) int delete_even(
    st_data_t key,
    st_data_t value,
    st_data_t argument)
{
    st_data_t* sum = cast(st_data_t*) argument;
    *sum += key;
    return key % 2 == 0 ? ST_DELETE : ST_CONTINUE;
}

private extern(C) int insert_or_increment(
    st_data_t* key,
    st_data_t* value,
    st_data_t argument,
    int existing)
{
    if (existing != 0)
        *value += argument;
    else
        *value = argument;
    return ST_CONTINUE;
}

private extern(C) int word_compare(st_data_t left, st_data_t right)
{
    return left != right;
}

private extern(C) st_index_t constant_hash(st_data_t key)
{
    return 7;
}

private int test_storage_representations(rpmalloc_heap_t* heap)
{
    st_table* table = st_init_numtable(heap);
    if (require(table !is null &&
            table.entry_power == 2 &&
            table.bin_power == 3 &&
            table.size_ind == 0))
        return 1;
    size_t expected_small_size =
        st_table.sizeof + 4 * 3 * size_t.sizeof;
    if (require(st_memsize(table) == expected_small_size))
        return 1;
    st_free_table(table);

    table = st_init_numtable_with_size(heap, 15);
    if (require(table !is null &&
            table.entry_power == 4 &&
            st_memsize(table) ==
                st_table.sizeof + 16 * 3 * size_t.sizeof))
        return 1;
    st_free_table(table);

    table = st_init_numtable_with_size(heap, 16);
    if (require(table !is null &&
            table.entry_power == 5 &&
            table.bin_power == 6 &&
            table.size_ind == 0 &&
            st_memsize(table) ==
                st_table.sizeof + 32 * 3 * size_t.sizeof + 64))
        return 1;
    st_free_table(table);

    table = st_init_numtable_with_size(heap, 128);
    if (require(table !is null &&
            table.entry_power == 8 &&
            table.bin_power == 9 &&
            table.size_ind == 1 &&
            st_memsize(table) ==
                st_table.sizeof +
                256 * 3 * size_t.sizeof +
                512 * ushort.sizeof))
        return 1;
    st_free_table(table);

    table = st_init_numtable_with_size(heap, 32_768);
    if (require(table !is null &&
            table.entry_power == 16 &&
            table.bin_power == 17 &&
            table.size_ind == 2))
        return 1;
    st_free_table(table);

    table = st_init_numtable_with_size(heap, 31);
    if (require(table !is null && table.entry_power == 5))
        return 1;
    foreach (st_data_t key; 0 .. 32)
        if (require(st_insert(table, key, key) == 0))
            return 1;
    foreach (st_data_t key; 0 .. 20)
    {
        st_data_t removed = key;
        if (require(st_delete(table, &removed, null) == 1))
            return 1;
    }
    uint rebuilds = table.rebuilds_num;
    if (require(st_insert(table, 100, 100) == 0 &&
            table.entry_power == 5 &&
            table.entries_start == 0 &&
            table.entries_bound == 13 &&
            table.rebuilds_num == rebuilds + 1))
        return 1;
    st_free_table(table);
    return 0;
}

private int test_collisions(rpmalloc_heap_t* heap)
{
    immutable st_hash_type collision_policy =
        st_hash_type(&word_compare, &constant_hash);
    st_table* table = st_init_table(heap, &collision_policy);
    if (require(table !is null))
        return 1;

    foreach (st_data_t key; 0 .. 100)
        if (require(st_insert(table, key, key + 500) == 0))
            return 1;
    foreach (st_data_t key; 0 .. 100)
    {
        st_data_t value;
        if (require(st_lookup(table, key, &value) == 1 &&
                value == key + 500))
            return 1;
    }
    foreach (st_data_t key; 0 .. 100)
    {
        if (key % 3 == 0)
        {
            st_data_t removed = key;
            if (require(st_delete(table, &removed, null) == 1))
                return 1;
        }
    }
    foreach (st_data_t key; 100 .. 150)
        if (require(st_insert(table, key, key + 500) == 0))
            return 1;
    foreach (st_data_t key; 100 .. 150)
    {
        st_data_t value;
        if (require(st_lookup(table, key, &value) == 1 &&
                value == key + 500))
            return 1;
    }

    st_free_table(table);
    return 0;
}

private int test_strings(rpmalloc_heap_t* heap)
{
    st_table* table = st_init_strtable(heap);
    if (require(table !is null))
        return 1;
    if (require(st_insert(table, cast(st_data_t) "a".ptr, 10) == 0))
        return 1;
    if (require(st_insert(table, cast(st_data_t) "b".ptr, 20) == 0))
        return 1;
    if (require(st_insert(table, cast(st_data_t) "c".ptr, 30) == 0))
        return 1;

    st_data_t value;
    if (require(st_lookup(
            table, cast(st_data_t) "b".ptr, &value) == 1 &&
            value == 20))
        return 1;
    if (require(st_insert(
            table, cast(st_data_t) "b".ptr, 200) == 1))
        return 1;
    if (require(st_table_size(table) == 3))
        return 1;

    st_data_t key = cast(st_data_t) "c".ptr;
    if (require(st_delete(table, &key, &value) == 1 && value == 30))
        return 1;
    if (require(st_insert(table, cast(st_data_t) "c".ptr, 300) == 0))
        return 1;

    st_data_t[3] keys;
    st_data_t[3] values;
    if (require(st_keys(table, keys.ptr, keys.length) == 3))
        return 1;
    if (require(strcmp(cast(const(char)*) keys[0], "a".ptr) == 0))
        return 1;
    if (require(strcmp(cast(const(char)*) keys[1], "b".ptr) == 0))
        return 1;
    if (require(strcmp(cast(const(char)*) keys[2], "c".ptr) == 0))
        return 1;
    if (require(st_values(table, values.ptr, values.length) == 3))
        return 1;
    if (require(values[0] == 10 && values[1] == 200 &&
            values[2] == 300))
        return 1;

    st_table* copy = st_copy(table);
    if (require(copy !is null))
        return 1;
    if (require(st_insert(copy, cast(st_data_t) "a".ptr, 999) == 1))
        return 1;
    if (require(st_lookup(
            table, cast(st_data_t) "a".ptr, &value) == 1 &&
            value == 10))
        return 1;

    st_free_table(copy);
    st_free_table(table);
    return 0;
}

private int test_numbers(rpmalloc_heap_t* heap)
{
    if (require(st_init_numtable_with_size(heap, size_t.max) is null))
        return 1;

    st_table* table = st_init_numtable(heap);
    if (require(table !is null))
        return 1;

    foreach (st_data_t key; 0 .. 1000)
        if (require(st_insert(table, key, key * 10) == 0))
            return 1;

    foreach (st_data_t key; 0 .. 1000)
    {
        st_data_t value;
        if (require(st_lookup(table, key, &value) == 1 &&
                value == key * 10))
            return 1;
    }

    st_data_t shifted_key;
    st_data_t shifted_value;
    if (require(st_shift(table, &shifted_key, &shifted_value) == 1 &&
            shifted_key == 0 && shifted_value == 0))
        return 1;

    st_clear(table);
    foreach (st_data_t key; 0 .. 10)
        if (require(st_insert(table, key, key + 1000) == 0))
            return 1;

    st_data_t sum;
    if (require(st_foreach(
            table, &delete_even, cast(st_data_t) &sum) == 0))
        return 1;
    if (require(sum == 45 && st_table_size(table) == 5))
        return 1;

    st_clear(table);
    if (require(st_update(table, 7, &insert_or_increment, 10) == 0))
        return 1;
    if (require(st_update(table, 7, &insert_or_increment, 5) == 1))
        return 1;
    st_data_t value;
    if (require(st_lookup(table, 7, &value) == 1 && value == 15))
        return 1;

    st_free_table(table);
    return 0;
}

private int test_case_insensitive(rpmalloc_heap_t* heap)
{
    st_table* table = st_init_strcasetable(heap);
    if (require(table !is null))
        return 1;
    if (require(st_insert(
            table, cast(st_data_t) "Hello".ptr, 42) == 0))
        return 1;
    st_data_t value;
    if (require(st_lookup(
            table, cast(st_data_t) "HELLO".ptr, &value) == 1 &&
            value == 42))
        return 1;
    if (require(st_insert(
            table, cast(st_data_t) "hello".ptr, 99) == 1))
        return 1;
    if (require(st_table_size(table) == 1))
        return 1;
    st_free_table(table);
    return 0;
}

extern(C) int main()
{
    if (rpmalloc_initialize(null) != 0)
        return EXIT_FAILURE;
    rpmalloc_heap_t* heap = rpmalloc_heap_acquire();
    if (heap is null)
        return EXIT_FAILURE;

    int result =
        test_storage_representations(heap) |
        test_collisions(heap) |
        test_strings(heap) |
        test_numbers(heap) |
        test_case_insensitive(heap);

    // This unrelated allocation proves that freeing tables does not clear the
    // caller-owned heap.
    void* unrelated = rpmalloc_heap_alloc(heap, 64);
    if (unrelated is null)
        result = 1;
    else
        rpmalloc_heap_free(heap, unrelated);

    rpmalloc_heap_release(heap);
    rpmalloc_finalize();
    return result == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
