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

private struct ReentrantContext
{
    st_table* table;
    void* extra_keys;
    size_t extra_count;
    int triggered;
}

private struct ReentrantKey
{
    ReentrantContext* context;
    st_data_t value;
}

private extern(C) st_index_t reentrant_hash(st_data_t raw_key)
{
    ReentrantKey* key = cast(ReentrantKey*) raw_key;
    return key.value & 1;
}

private extern(C) int reentrant_compare(
    st_data_t raw_left,
    st_data_t raw_right)
{
    ReentrantKey* left = cast(ReentrantKey*) raw_left;
    ReentrantKey* right = cast(ReentrantKey*) raw_right;
    ReentrantContext* context = left.context;
    if (context !is null && context.triggered == 0)
    {
        context.triggered = 1;
        ReentrantKey* extras =
            cast(ReentrantKey*) context.extra_keys;
        foreach (size_t index; 0 .. context.extra_count)
            st_insert(
                context.table,
                cast(st_data_t) &extras[index],
                extras[index].value);
    }
    return left.value != right.value;
}

private struct ForeachInsertContext
{
    st_table* table;
    int triggered;
}

private extern(C) int insert_during_foreach(
    st_data_t key,
    st_data_t value,
    st_data_t raw_context)
{
    ForeachInsertContext* context =
        cast(ForeachInsertContext*) raw_context;
    if (context.triggered == 0)
    {
        context.triggered = 1;
        foreach (st_data_t inserted; 100 .. 140)
            st_insert(context.table, inserted, inserted);
    }
    return ST_CONTINUE;
}

private int test_hash_vectors()
{
    if (require(st_numhash(
            cast(st_data_t) 0x123456789abcdef0UL) ==
            cast(st_index_t) 10_656_780_064_946_940_997UL))
        return 1;

    enum seed = cast(st_index_t) 0x811c9dc5;
    if (require(st_hash("".ptr, 0, seed) ==
            cast(st_index_t) 9_674_187_198_854_108_257UL))
        return 1;
    if (require(st_hash("a".ptr, 1, seed) ==
            cast(st_index_t) 13_275_174_337_784_471_242UL))
        return 1;
    if (require(st_hash("Laser-D".ptr, 7, seed) ==
            cast(st_index_t) 13_965_654_480_679_965_192UL))
        return 1;
    if (require(st_hashtype_str.hash(
            cast(st_data_t) "Laser-D".ptr) ==
            cast(st_index_t) 13_965_654_480_679_965_192UL))
        return 1;
    if (require(st_hashtype_strcase.hash(
            cast(st_data_t) "Laser-D".ptr) ==
            cast(st_index_t) 9_466_887_608_465_540_149UL))
        return 1;
    if (require(st_hash("abcdefgh".ptr, 8, seed) ==
            cast(st_index_t) 2_012_693_205_819_137_116UL))
        return 1;
    if (require(st_hash("abcdefghi".ptr, 9, seed) ==
            cast(st_index_t) 2_081_646_479_900_152_290UL))
        return 1;
    if (require(st_hash_uint32(123, 456) ==
            cast(st_index_t) 8_525_600_690_438_344_755UL))
        return 1;
    if (require(st_hash_uint(123, 456) ==
            cast(st_index_t) 623_087_270_292_831_951UL))
        return 1;
    if (require(st_hash_end(123) ==
            cast(st_index_t) 15_658_915_475_255_836_868UL))
        return 1;
    return 0;
}

private int test_reentrant_callbacks(Heap* heap)
{
    immutable st_hash_type policy =
        st_hash_type(&reentrant_compare, &reentrant_hash);
    ReentrantContext context;
    ReentrantKey base = ReentrantKey(&context, 1);
    ReentrantKey query = ReentrantKey(&context, 1);
    ReentrantKey[20] extras;
    foreach (size_t index; 0 .. extras.length)
        extras[index] = ReentrantKey(&context, index + 10);

    st_table* table = st_init_table(heap, &policy);
    if (require(table !is null))
        return 1;
    context.table = table;
    context.extra_keys = extras.ptr;
    context.extra_count = extras.length;
    if (require(st_insert(
            table, cast(st_data_t) &base, 77) == 0))
        return 1;

    st_data_t value;
    if (require(st_lookup(
            table, cast(st_data_t) &query, &value) == 1 &&
            value == 77 &&
            context.triggered == 1 &&
            st_table_size(table) == extras.length + 1))
        return 1;
    st_free_table(table);

    table = st_init_numtable(heap);
    if (require(table !is null))
        return 1;
    foreach (st_data_t key; 0 .. 16)
        if (require(st_insert(table, key, key) == 0))
            return 1;
    ForeachInsertContext foreach_context =
        ForeachInsertContext(table, 0);
    if (require(st_foreach(
            table,
            &insert_during_foreach,
            cast(st_data_t) &foreach_context) == 0))
        return 1;
    if (require(foreach_context.triggered == 1 &&
            st_table_size(table) == 56))
        return 1;
    foreach (st_data_t key; 100 .. 140)
        if (require(st_is_member(table, key) == 1))
            return 1;
    st_free_table(table);
    return 0;
}

private int test_storage_representations(Heap* heap)
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

private int test_collisions(Heap* heap)
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

private int test_strings(Heap* heap)
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

private int test_numbers(Heap* heap)
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

private int test_case_insensitive(Heap* heap)
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
    if (initialize(null) != 0)
        return EXIT_FAILURE;
    Heap* heap = acquireHeap();
    if (heap is null)
        return EXIT_FAILURE;

    int result =
        test_hash_vectors() |
        test_reentrant_callbacks(heap) |
        test_storage_representations(heap) |
        test_collisions(heap) |
        test_strings(heap) |
        test_numbers(heap) |
        test_case_insensitive(heap);

    // This unrelated allocation proves that freeing tables does not clear the
    // caller-owned heap.
    void* unrelated = allocateFromHeap(heap, 64);
    if (unrelated is null)
        result = 1;
    else
        freeFromHeap(heap, unrelated);

    releaseHeap(heap);
    finalize();
    return result == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
