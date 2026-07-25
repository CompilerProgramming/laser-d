/**
 * An insertion-ordered hash table for Laser-D.
 *
 * The API is based on the public-domain st hash table used by Ruby. Keys and
 * values are machine words, so either may hold an integer or a pointer on
 * Laser-D's supported 64-bit targets.
 *
 * A table borrows its rpmalloc heap. The caller must keep the heap alive until
 * st_free_table has returned. The table frees only its own allocations.
 */
module laserd.hash;

import core.stdc.stddef : size_t;
import core.stdc.string : memcpy, memset, strcmp, strlen;
import laserd.rpmalloc :
    rpmalloc_heap_t,
    rpmalloc_heap_alloc,
    rpmalloc_heap_free;

alias st_data_t = size_t;
alias st_index_t = size_t;
/* The type of hashes. */
alias st_hash_t = st_index_t;

alias st_compare_func = extern(C) int function(st_data_t, st_data_t);
alias st_hash_func = extern(C) st_index_t function(st_data_t);
alias st_insert_callback_func = extern(C) st_data_t function(st_data_t);
alias st_update_callback_func =
    extern(C) int function(st_data_t*, st_data_t*, st_data_t, int);
alias st_foreach_callback_func =
    extern(C) int function(st_data_t, st_data_t, st_data_t);
alias st_foreach_check_callback_func =
    extern(C) int function(st_data_t, st_data_t, st_data_t, int);

enum ST_ERROR = -1;
enum ST_CONTINUE = 0;
enum ST_STOP = 1;
enum ST_DELETE = 2;
enum ST_CHECK = 3;
enum ST_REPLACE = 4;

/*
 * Reserved bin values. Real entry indices are offset by ENTRY_BASE so these
 * values can represent an empty bin and a bin whose entry was deleted.
 */
private enum st_index_t EMPTY_BIN = 0;
private enum st_index_t DELETED_BIN = 1;
private enum st_index_t ENTRY_BASE = 2;

/*
 * RESERVED_HASH is used to mark a deleted entry. A real hash with that value
 * is mapped to zero; such a mapping should be extremely rare.
 */
private enum st_hash_t DELETED_HASH = st_hash_t.max;
private enum st_hash_t RESERVED_HASH = st_hash_t.max;

/* Values used when an entry or bin was not found or a search was rebuilt. */
private enum st_index_t NO_INDEX = st_index_t.max;
private enum st_index_t REBUILT_INDEX = st_index_t.max - 1;

/* Power of two defining the minimal number of allocated entries. */
private enum ubyte MINIMAL_POWER2 = 2;
private enum ubyte MAX_POWER2 = 62;

/*
 * If the allocated-entry power is no greater than this value, do not allocate
 * bins and use a linear search.
 */
private enum ubyte MAX_POWER2_WITHOUT_BINS = 4;

/*
 * If the entry count is at least this many times smaller than the entry array,
 * rebuilding may compact rather than grow the table.
 */
private enum st_index_t REBUILD_THRESHOLD = 4;

struct st_hash_type
{
    st_compare_func compare;
    st_hash_func hash;
}

private struct st_table_entry
{
    st_hash_t hash;
    st_data_t key;
    st_data_t record;
}

struct st_table
{
    /*
     * Cached table features. entry_power and bin_power are powers of two;
     * size_ind selects 8-, 16-, 32-, or 64-bit packed bins.
     */
    ubyte entry_power;
    ubyte bin_power;
    ubyte size_ind;
    rpmalloc_heap_t* heap;
    const(st_hash_type)* type;
    st_index_t num_entries;
    st_index_t entries_start;
    st_index_t entries_bound;
    uint rebuilds_num;
    st_table_entry* entries;
}

private st_hash_t normalize_hash(st_hash_t value)
{
    return value == RESERVED_HASH ? 0 : value;
}

private st_hash_t do_hash(const(st_table)* table, st_data_t key)
{
    return normalize_hash(table.type.hash(key));
}

private bool keys_equal(
    const(st_table)* table,
    st_data_t left,
    st_data_t right)
{
    return left == right || table.type.compare(left, right) == 0;
}

/*
 * As keys_equal, but REBUILT is set when the table was rebuilt during the
 * comparison. A callback is allowed to re-enter the table, so callers must
 * discard cached entry pointers and retry after a rebuild.
 */
private bool entry_matches(
    const(st_table)* table,
    st_index_t entry_index,
    st_hash_t hash,
    st_data_t key,
    bool* rebuilt)
{
    uint old_rebuilds = table.rebuilds_num;
    const(st_table_entry)* entry = &table.entries[entry_index];
    bool equal = entry.hash == hash &&
        keys_equal(table, key, entry.key);
    *rebuilt = old_rebuilds != table.rebuilds_num;
    return equal;
}

private int get_power2(st_index_t size)
{
    /* Return the smallest n >= MINIMAL_POWER2 for which 2^^n > size. */
    ubyte power = MINIMAL_POWER2;
    while (power <= MAX_POWER2 &&
        (cast(st_index_t) 1 << power) <= size)
        ++power;
    return power > MAX_POWER2 ? ST_ERROR : power;
}

private st_index_t allocated_entries(const(st_table)* table)
{
    return cast(st_index_t) 1 << table.entry_power;
}

private st_index_t bins_count(const(st_table)* table)
{
    return cast(st_index_t) 1 << table.bin_power;
}

private bool has_bins(const(st_table)* table)
{
    return table.entry_power > MAX_POWER2_WITHOUT_BINS;
}

private ubyte size_index_for_power(ubyte power)
{
    if (power < 8)
        return 0;
    if (power < 16)
        return 1;
    if (power < 32)
        return 2;
    return 3;
}

private size_t bin_element_size(ubyte size_index)
{
    if (size_index == 0)
        return ubyte.sizeof;
    if (size_index == 1)
        return ushort.sizeof;
    if (size_index == 2)
        return uint.sizeof;
    return st_index_t.sizeof;
}

private size_t entries_size(const(st_table)* table)
{
    return allocated_entries(table) * st_table_entry.sizeof;
}

private size_t bins_size(const(st_table)* table)
{
    return has_bins(table)
        ? bins_count(table) * bin_element_size(table.size_ind)
        : 0;
}

private void* bins_pointer(const(st_table)* table)
{
    if (!has_bins(table))
        return null;
    return cast(void*)
        (cast(ubyte*) table.entries + entries_size(table));
}

private st_index_t get_bin(const(st_table)* table, st_index_t index)
{
    /* Return the INDEX-th packed bin according to the table's size index. */
    void* bins = bins_pointer(table);
    if (table.size_ind == 0)
        return (cast(ubyte*) bins)[index];
    if (table.size_ind == 1)
        return (cast(ushort*) bins)[index];
    if (table.size_ind == 2)
        return (cast(uint*) bins)[index];
    return (cast(st_index_t*) bins)[index];
}

private void set_bin(
    st_table* table,
    st_index_t index,
    st_index_t value)
{
    /* Store VALUE in the INDEX-th packed bin. */
    void* bins = bins_pointer(table);
    if (table.size_ind == 0)
        (cast(ubyte*) bins)[index] = cast(ubyte) value;
    else if (table.size_ind == 1)
        (cast(ushort*) bins)[index] = cast(ushort) value;
    else if (table.size_ind == 2)
        (cast(uint*) bins)[index] = cast(uint) value;
    else
        (cast(st_index_t*) bins)[index] = value;
}

private void initialize_bins(st_table* table)
{
    if (has_bins(table))
        memset(bins_pointer(table), 0, bins_size(table));
}

private st_index_t secondary_hash(
    st_index_t index,
    const(st_table)* table,
    st_index_t* perturb)
{
    /*
     * The eventual recurrence is a full-cycle linear congruential generator:
     * Xnext = 5 * Xprev + 1 modulo a power of two. The Hull-Dobell conditions
     * therefore guarantee that every bin is visited in the extreme case.
     */
    *perturb >>= 11;
    return ((index << 2) + index + *perturb + 1) &
        (bins_count(table) - 1);
}

private st_index_t find_entry_linear(
    const(st_table)* table,
    st_hash_t hash,
    st_data_t key)
{
    /* Small tables have no bins and are searched directly in entry order. */
    foreach (st_index_t index;
        table.entries_start .. table.entries_bound)
    {
        bool rebuilt;
        bool equal = entry_matches(
            table, index, hash, key, &rebuilt);
        if (rebuilt)
            return REBUILT_INDEX;
        if (equal)
            return index;
    }
    return NO_INDEX;
}

private st_index_t find_entry_binned(
    const(st_table)* table,
    st_hash_t hash,
    st_data_t key)
{
    st_index_t bin_index = hash & (bins_count(table) - 1);
    st_index_t perturb = hash;
    while (true)
    {
        st_index_t bin = get_bin(table, bin_index);
        if (bin == EMPTY_BIN)
            return NO_INDEX;
        if (bin >= ENTRY_BASE)
        {
            st_index_t entry_index = bin - ENTRY_BASE;
            bool rebuilt;
            bool equal = entry_matches(
                table, entry_index, hash, key, &rebuilt);
            if (rebuilt)
                return REBUILT_INDEX;
            if (equal)
                return entry_index;
        }
        bin_index = secondary_hash(bin_index, table, &perturb);
    }
}

private st_index_t find_entry_index(
    const(st_table)* table,
    st_hash_t hash,
    st_data_t key)
{
    return has_bins(table)
        ? find_entry_binned(table, hash, key)
        : find_entry_linear(table, hash, key);
}

private st_index_t find_bin_for_entry(
    const(st_table)* table,
    st_hash_t hash,
    st_data_t key)
{
    st_index_t bin_index = hash & (bins_count(table) - 1);
    st_index_t perturb = hash;
    while (true)
    {
        st_index_t bin = get_bin(table, bin_index);
        if (bin == EMPTY_BIN)
            return NO_INDEX;
        if (bin >= ENTRY_BASE)
        {
            st_index_t entry_index = bin - ENTRY_BASE;
            bool rebuilt;
            bool equal = entry_matches(
                table, entry_index, hash, key, &rebuilt);
            if (rebuilt)
                return REBUILT_INDEX;
            if (equal)
                return bin_index;
        }
        bin_index = secondary_hash(bin_index, table, &perturb);
    }
}

private st_index_t find_insertion_bin(
    const(st_table)* table,
    st_hash_t hash)
{
    st_index_t bin_index = hash & (bins_count(table) - 1);
    st_index_t perturb = hash;
    st_index_t first_deleted = NO_INDEX;
    while (true)
    {
        st_index_t bin = get_bin(table, bin_index);
        if (bin == EMPTY_BIN)
            return first_deleted == NO_INDEX ? bin_index : first_deleted;
        if (bin == DELETED_BIN && first_deleted == NO_INDEX)
            first_deleted = bin_index;
        bin_index = secondary_hash(bin_index, table, &perturb);
    }
}

/*
 * Return the entry index for HASH and KEY through the function result and the
 * bin to use for a new entry through INSERTION_BIN. A deleted bin may be
 * reused, but an empty bin terminates the search. REBUILT_INDEX tells the
 * caller to restart because a comparison callback rebuilt the table.
 */
private st_index_t find_entry_and_reserve(
    const(st_table)* table,
    st_hash_t hash,
    st_data_t key,
    st_index_t* insertion_bin)
{
    if (!has_bins(table))
    {
        *insertion_bin = NO_INDEX;
        return find_entry_linear(table, hash, key);
    }

    st_index_t bin_index = hash & (bins_count(table) - 1);
    st_index_t perturb = hash;
    st_index_t first_deleted = NO_INDEX;
    while (true)
    {
        st_index_t bin = get_bin(table, bin_index);
        if (bin == EMPTY_BIN)
        {
            *insertion_bin =
                first_deleted == NO_INDEX ? bin_index : first_deleted;
            return NO_INDEX;
        }
        if (bin == DELETED_BIN)
        {
            if (first_deleted == NO_INDEX)
                first_deleted = bin_index;
        }
        else
        {
            st_index_t entry_index = bin - ENTRY_BASE;
            bool rebuilt;
            bool equal = entry_matches(
                table, entry_index, hash, key, &rebuilt);
            if (rebuilt)
                return REBUILT_INDEX;
            if (equal)
            {
                *insertion_bin = bin_index;
                return entry_index;
            }
        }
        bin_index = secondary_hash(bin_index, table, &perturb);
    }
}

private int set_features(st_table* table, st_index_t requested_size)
{
    int power = get_power2(requested_size);
    if (power == ST_ERROR)
        return ST_ERROR;
    table.entry_power = cast(ubyte) power;
    table.bin_power = cast(ubyte) (power + 1);
    table.size_ind = size_index_for_power(table.entry_power);
    return 0;
}

private bool valid_storage_size(const(st_table)* table)
{
    st_index_t count = allocated_entries(table);
    if (count > size_t.max / st_table_entry.sizeof)
        return false;
    size_t entry_bytes = count * st_table_entry.sizeof;
    size_t bin_bytes = bins_size(table);
    return bin_bytes <= size_t.max - entry_bytes;
}

private st_table_entry* allocate_storage(st_table* table)
{
    /*
     * The entries array is immediately followed by the packed bins. Keep the
     * original single-allocation layout while allocating from the borrowed
     * rpmalloc heap.
     */
    if (!valid_storage_size(table))
        return null;
    return cast(st_table_entry*) rpmalloc_heap_alloc(
        table.heap,
        entries_size(table) + bins_size(table));
}

private void build_bins(st_table* table)
{
    initialize_bins(table);
    if (!has_bins(table))
        return;
    foreach (st_index_t index;
        table.entries_start .. table.entries_bound)
    {
        st_table_entry* entry = &table.entries[index];
        if (entry.hash != DELETED_HASH)
            set_bin(
                table,
                find_insertion_bin(table, entry.hash),
                index + ENTRY_BASE);
    }
}

private void compact_in_place(st_table* table)
{
    /* Compaction removes deleted entries without changing allocation size. */
    st_index_t destination = 0;
    foreach (st_index_t source;
        table.entries_start .. table.entries_bound)
    {
        if (table.entries[source].hash != DELETED_HASH)
            table.entries[destination++] = table.entries[source];
    }
    table.entries_start = 0;
    table.entries_bound = destination;
    build_bins(table);
    ++table.rebuilds_num;
}

private int rebuild(st_table* table)
{
    /*
     * Rebuilding removes deleted bins and entries. Sparse-enough tables are
     * compacted in place; otherwise a replacement entries-and-bins block is
     * created and moved into the table.
     */
    st_index_t old_capacity = allocated_entries(table);
    if ((2 * table.num_entries <= old_capacity &&
            REBUILD_THRESHOLD * table.num_entries > old_capacity) ||
        table.num_entries < (cast(st_index_t) 1 << MINIMAL_POWER2))
    {
        compact_in_place(table);
        return 0;
    }

    st_table replacement;
    memset(&replacement, 0, st_table.sizeof);
    replacement.heap = table.heap;
    replacement.type = table.type;
    if (set_features(&replacement, 2 * table.num_entries - 1) ==
        ST_ERROR)
        return ST_ERROR;
    replacement.entries = allocate_storage(&replacement);
    if (replacement.entries is null)
        return ST_ERROR;

    foreach (st_index_t index;
        table.entries_start .. table.entries_bound)
    {
        if (table.entries[index].hash != DELETED_HASH)
            replacement.entries[replacement.entries_bound++] =
                table.entries[index];
    }
    replacement.num_entries = table.num_entries;
    replacement.rebuilds_num = table.rebuilds_num + 1;
    build_bins(&replacement);

    rpmalloc_heap_free(table.heap, table.entries);
    table.entry_power = replacement.entry_power;
    table.bin_power = replacement.bin_power;
    table.size_ind = replacement.size_ind;
    table.entries_start = 0;
    table.entries_bound = replacement.entries_bound;
    table.entries = replacement.entries;
    table.rebuilds_num = replacement.rebuilds_num;
    return 0;
}

private int ensure_insert_capacity(st_table* table)
{
    if (table.entries_bound < allocated_entries(table))
        return 0;
    return rebuild(table);
}

private st_table* allocate_table(
    rpmalloc_heap_t* heap,
    const(st_hash_type)* type,
    st_index_t requested_size)
{
    if (heap is null || type is null ||
        type.compare is null || type.hash is null)
        return null;

    st_table* table = cast(st_table*)
        rpmalloc_heap_alloc(heap, st_table.sizeof);
    if (table is null)
        return null;
    memset(table, 0, st_table.sizeof);
    table.heap = heap;
    table.type = type;
    if (set_features(table, requested_size) == ST_ERROR)
    {
        rpmalloc_heap_free(heap, table);
        return null;
    }
    table.entries = allocate_storage(table);
    if (table.entries is null)
    {
        rpmalloc_heap_free(heap, table);
        return null;
    }
    initialize_bins(table);
    return table;
}

st_table* st_init_table(
    rpmalloc_heap_t* heap,
    const(st_hash_type)* type)
{
    return allocate_table(heap, type, 0);
}

st_table* st_init_table_with_size(
    rpmalloc_heap_t* heap,
    const(st_hash_type)* type,
    st_index_t size)
{
    return allocate_table(heap, type, size);
}

private extern(C) int numeric_compare(st_data_t left, st_data_t right)
{
    return left != right;
}

private extern(C) st_index_t numeric_hash(st_data_t value)
{
    enum shift1 = 11;
    enum shift2 = 3;
    return (value >> shift1 | value << shift2) ^ (value >> shift2);
}

private extern(C) int string_compare(st_data_t left, st_data_t right)
{
    return strcmp(
        cast(const(char)*) left,
        cast(const(char)*) right);
}

private ubyte ascii_lower(ubyte value)
{
    if (value >= cast(ubyte) 'A' && value <= cast(ubyte) 'Z')
        return cast(ubyte) (value + ('a' - 'A'));
    return value;
}

private extern(C) int string_case_compare(
    st_data_t left,
    st_data_t right)
{
    return st_locale_insensitive_strcasecmp(
        cast(const(char)*) left,
        cast(const(char)*) right);
}

private extern(C) st_index_t string_hash(st_data_t key)
{
    const(char)* text = cast(const(char)*) key;
    return st_hash(
        text,
        strlen(text),
        cast(st_index_t) 0x811c9dc5);
}

private extern(C) st_index_t string_case_hash(st_data_t key)
{
    const(ubyte)* text = cast(const(ubyte)*) key;
    st_index_t value = cast(st_index_t) 0x811c9dc5;

    /*
     * FNV-1a hash each octet in the buffer.
     */
    while (*text != 0)
    {
        uint character = *text++;
        if (character - 'A' <= 'Z' - 'A')
            character += 'a' - 'A';
        value ^= character;

        /* Multiply by the 32-bit FNV magic prime. */
        value *= cast(st_index_t) 0x01000193;
    }
    return value;
}

immutable st_hash_type st_hashtype_num =
    st_hash_type(&numeric_compare, &numeric_hash);
immutable st_hash_type st_hashtype_str =
    st_hash_type(&string_compare, &string_hash);
immutable st_hash_type st_hashtype_strcase =
    st_hash_type(&string_case_compare, &string_case_hash);

st_table* st_init_numtable(rpmalloc_heap_t* heap)
{
    return st_init_table(heap, &st_hashtype_num);
}

st_table* st_init_numtable_with_size(
    rpmalloc_heap_t* heap,
    st_index_t size)
{
    return st_init_table_with_size(heap, &st_hashtype_num, size);
}

st_table* st_init_strtable(rpmalloc_heap_t* heap)
{
    return st_init_table(heap, &st_hashtype_str);
}

st_table* st_init_strtable_with_size(
    rpmalloc_heap_t* heap,
    st_index_t size)
{
    return st_init_table_with_size(heap, &st_hashtype_str, size);
}

st_table* st_init_strcasetable(rpmalloc_heap_t* heap)
{
    return st_init_table(heap, &st_hashtype_strcase);
}

st_table* st_init_strcasetable_with_size(
    rpmalloc_heap_t* heap,
    st_index_t size)
{
    return st_init_table_with_size(heap, &st_hashtype_strcase, size);
}

st_index_t st_table_size(const(st_table)* table)
{
    return table.num_entries;
}

/* Return the byte size allocated for TABLE, including its table header. */
size_t st_memsize(const(st_table)* table)
{
    return st_table.sizeof + entries_size(table) + bins_size(table);
}

/*
 * Find KEY in TABLE. Return nonzero when found and, unless VALUE is null,
 * store the associated record through VALUE.
 */
int st_lookup(st_table* table, st_data_t key, st_data_t* value)
{
    st_hash_t hash = do_hash(table, key);
    while (true)
    {
        st_index_t index = find_entry_index(table, hash, key);
        if (index == REBUILT_INDEX)
            continue;
        if (index == NO_INDEX)
            return 0;
        if (value !is null)
            *value = table.entries[index].record;
        return 1;
    }
}

int st_is_member(st_table* table, st_data_t key)
{
    return st_lookup(table, key, null);
}

int st_get_key(st_table* table, st_data_t key, st_data_t* result)
{
    st_hash_t hash = do_hash(table, key);
    while (true)
    {
        st_index_t index = find_entry_index(table, hash, key);
        if (index == REBUILT_INDEX)
            continue;
        if (index == NO_INDEX)
            return 0;
        if (result !is null)
            *result = table.entries[index].key;
        return 1;
    }
}

/*
 * Insert KEY and VALUE and return zero. If KEY already exists, update its
 * value and return nonzero. Return ST_ERROR if growth allocation fails.
 */
int st_insert(st_table* table, st_data_t key, st_data_t value)
{
    st_hash_t hash = do_hash(table, key);
    while (true)
    {
        if (ensure_insert_capacity(table) == ST_ERROR)
            return ST_ERROR;
        st_index_t insertion_bin;
        st_index_t index = find_entry_and_reserve(
            table, hash, key, &insertion_bin);
        if (index == REBUILT_INDEX)
            continue;
        if (index != NO_INDEX)
        {
            table.entries[index].record = value;
            return 1;
        }

        st_index_t entry_index = table.entries_bound++;
        table.entries[entry_index].hash = hash;
        table.entries[entry_index].key = key;
        table.entries[entry_index].record = value;
        if (insertion_bin != NO_INDEX)
            set_bin(
                table,
                insertion_bin,
                entry_index + ENTRY_BASE);
        ++table.num_entries;
        return 0;
    }
}

int st_insert2(
    st_table* table,
    st_data_t key,
    st_data_t value,
    st_insert_callback_func transform)
{
    st_hash_t hash = do_hash(table, key);
    while (true)
    {
        if (ensure_insert_capacity(table) == ST_ERROR)
            return ST_ERROR;
        st_index_t insertion_bin;
        st_index_t index = find_entry_and_reserve(
            table, hash, key, &insertion_bin);
        if (index == REBUILT_INDEX)
            continue;
        if (index != NO_INDEX)
        {
            table.entries[index].record = value;
            return 1;
        }

        st_data_t stored_key = transform(key);
        st_index_t entry_index = table.entries_bound++;
        table.entries[entry_index].hash = hash;
        table.entries[entry_index].key = stored_key;
        table.entries[entry_index].record = value;
        if (insertion_bin != NO_INDEX)
            set_bin(
                table,
                insertion_bin,
                entry_index + ENTRY_BASE);
        ++table.num_entries;
        return 0;
    }
}

/*
 * Insert directly when the caller knows KEY is absent. Unlike the original
 * void C entry point, return ST_ERROR when growth allocation fails.
 */
int st_add_direct(st_table* table, st_data_t key, st_data_t value)
{
    if (ensure_insert_capacity(table) == ST_ERROR)
        return ST_ERROR;
    st_hash_t hash = do_hash(table, key);
    st_index_t entry_index = table.entries_bound++;
    table.entries[entry_index] = st_table_entry(hash, key, value);
    if (has_bins(table))
        set_bin(
            table,
            find_insertion_bin(table, hash),
            entry_index + ENTRY_BASE);
    ++table.num_entries;
    return 0;
}

private void update_start_after_delete(st_table* table)
{
    while (table.entries_start < table.entries_bound &&
        table.entries[table.entries_start].hash == DELETED_HASH)
        ++table.entries_start;
}

int st_delete(st_table* table, st_data_t* key, st_data_t* value)
{
    st_hash_t hash = do_hash(table, *key);
    while (true)
    {
        st_index_t bin_index = NO_INDEX;
        st_index_t entry_index;
        if (has_bins(table))
        {
            bin_index = find_bin_for_entry(table, hash, *key);
            if (bin_index == REBUILT_INDEX)
                continue;
            if (bin_index == NO_INDEX)
            {
                if (value !is null)
                    *value = 0;
                return 0;
            }
            entry_index = get_bin(table, bin_index) - ENTRY_BASE;
        }
        else
        {
            entry_index = find_entry_linear(table, hash, *key);
            if (entry_index == REBUILT_INDEX)
                continue;
            if (entry_index == NO_INDEX)
            {
                if (value !is null)
                    *value = 0;
                return 0;
            }
        }

        st_table_entry* entry = &table.entries[entry_index];
        *key = entry.key;
        if (value !is null)
            *value = entry.record;
        entry.hash = DELETED_HASH;
        if (has_bins(table))
            set_bin(table, bin_index, DELETED_BIN);
        --table.num_entries;
        update_start_after_delete(table);
        return 1;
    }
}

int st_delete_safe(
    st_table* table,
    st_data_t* key,
    st_data_t* value,
    st_data_t never)
{
    return st_delete(table, key, value);
}

void st_cleanup_safe(st_table* table, st_data_t never)
{
}

int st_shift(st_table* table, st_data_t* key, st_data_t* value)
{
    if (table.num_entries == 0)
    {
        if (value !is null)
            *value = 0;
        return 0;
    }
    st_table_entry* entry = &table.entries[table.entries_start];
    *key = entry.key;
    return st_delete(table, key, value);
}

/* Make TABLE empty while retaining its current entries-and-bins allocation. */
void st_clear(st_table* table)
{
    table.num_entries = 0;
    table.entries_start = 0;
    table.entries_bound = 0;
    initialize_bins(table);
    ++table.rebuilds_num;
}

st_table* st_copy(st_table* old_table)
{
    st_table* table = allocate_table(
        old_table.heap,
        old_table.type,
        allocated_entries(old_table) - 1);
    if (table is null)
        return null;

    table.num_entries = old_table.num_entries;
    table.entries_start = old_table.entries_start;
    table.entries_bound = old_table.entries_bound;
    table.rebuilds_num = old_table.rebuilds_num;
    memcpy(
        table.entries,
        old_table.entries,
        entries_size(old_table) + bins_size(old_table));
    return table;
}

/*
 * Apply CALLBACK to an existing entry or to a proposed new entry. The key may
 * be altered only to an equal key with the same hash, matching the C contract.
 */
int st_update(
    st_table* table,
    st_data_t key,
    st_update_callback_func callback,
    st_data_t argument)
{
    st_hash_t hash = do_hash(table, key);
    st_index_t index;
    do
        index = find_entry_index(table, hash, key);
    while (index == REBUILT_INDEX);
    int existing = index == NO_INDEX ? 0 : 1;
    st_data_t updated_key = existing ? table.entries[index].key : key;
    st_data_t updated_value =
        existing ? table.entries[index].record : 0;
    uint rebuilds = table.rebuilds_num;
    int action = callback(
        &updated_key,
        &updated_value,
        argument,
        existing);

    /*
     * The C implementation asserts that an update callback does not rebuild
     * the table. Laser-D has no runtime assert, so report the violation
     * explicitly instead of using an entry index from freed storage.
     */
    if (rebuilds != table.rebuilds_num)
        return ST_ERROR;

    if (action == ST_DELETE)
    {
        if (existing)
            st_delete(table, &key, null);
        return existing;
    }
    if (action == ST_STOP)
        return existing;
    if (existing)
    {
        table.entries[index].key = updated_key;
        table.entries[index].record = updated_value;
        return 1;
    }
    return st_insert(table, updated_key, updated_value);
}

int st_foreach(
    st_table* table,
    st_foreach_callback_func callback,
    st_data_t argument)
{
    st_index_t index = table.entries_start;
    while (index < table.entries_bound)
    {
        st_table_entry* entry = &table.entries[index];
        if (entry.hash != DELETED_HASH)
        {
            st_data_t key = entry.key;
            st_data_t record = entry.record;
            st_hash_t hash = entry.hash;
            uint rebuilds = table.rebuilds_num;
            int action = callback(key, record, argument);

            /*
             * The bound can change inside the loop even without rebuilding,
             * for example through insertion. After rebuilding, re-find the
             * current entry because the old entries pointer and index may no
             * longer identify it.
             */
            if (rebuilds != table.rebuilds_num)
            {
                do
                    index = find_entry_index(table, hash, key);
                while (index == REBUILT_INDEX);
                if (index == NO_INDEX)
                    continue;
            }
            if (action == ST_STOP)
                return 0;
            if (action == ST_DELETE)
                st_delete(table, &key, null);
            else if (action != ST_CONTINUE && action != ST_CHECK)
                return 1;
        }
        ++index;
    }
    return 0;
}

int st_foreach_check(
    st_table* table,
    st_foreach_check_callback_func callback,
    st_data_t argument,
    st_data_t never)
{
    st_index_t index = table.entries_start;
    while (index < table.entries_bound)
    {
        st_table_entry* entry = &table.entries[index];
        if (entry.hash != DELETED_HASH)
        {
            st_data_t key = entry.key;
            st_data_t record = entry.record;
            st_hash_t hash = entry.hash;
            uint rebuilds = table.rebuilds_num;
            int action = callback(
                key,
                record,
                argument,
                0);
            if (rebuilds != table.rebuilds_num)
            {
                do
                    index = find_entry_index(table, hash, key);
                while (index == REBUILT_INDEX);
                if (index == NO_INDEX)
                {
                    callback(0, 0, argument, 1);
                    return 1;
                }
            }
            if (action == ST_STOP)
                return 0;
            if (action == ST_DELETE)
                st_delete(table, &key, null);
            else if (action != ST_CONTINUE && action != ST_CHECK)
                return 1;
        }
        ++index;
    }
    return 0;
}

int st_foreach_with_replace(
    st_table* table,
    st_foreach_check_callback_func callback,
    st_update_callback_func replace,
    st_data_t argument)
{
    st_index_t index = table.entries_start;
    while (index < table.entries_bound)
    {
        st_table_entry* entry = &table.entries[index];
        if (entry.hash != DELETED_HASH)
        {
            st_data_t key = entry.key;
            st_data_t record = entry.record;
            st_hash_t hash = entry.hash;
            uint rebuilds = table.rebuilds_num;
            int action = callback(
                key,
                record,
                argument,
                0);
            if (rebuilds != table.rebuilds_num)
            {
                do
                    index = find_entry_index(table, hash, key);
                while (index == REBUILT_INDEX);
                if (index == NO_INDEX)
                {
                    callback(0, 0, argument, 1);
                    return 1;
                }
                entry = &table.entries[index];
            }
            if (action == ST_STOP)
                return 0;
            if (action == ST_DELETE)
                st_delete(table, &key, null);
            else if (action == ST_REPLACE)
            {
                st_data_t value = entry.record;
                rebuilds = table.rebuilds_num;
                int replace_action =
                    replace(&key, &value, argument, 1);
                if (rebuilds != table.rebuilds_num)
                    return ST_ERROR;
                if (replace_action == ST_DELETE)
                {
                    st_data_t old_key = key;
                    st_delete(table, &old_key, null);
                }
                else
                {
                    entry.key = key;
                    entry.record = value;
                }
            }
            else if (action != ST_CONTINUE && action != ST_CHECK)
                return 1;
        }
        ++index;
    }
    return 0;
}

st_index_t st_keys(
    st_table* table,
    st_data_t* keys,
    st_index_t size)
{
    st_index_t count = 0;
    foreach (st_index_t index; table.entries_start .. table.entries_bound)
    {
        if (table.entries[index].hash != DELETED_HASH)
        {
            if (count == size)
                break;
            keys[count++] = table.entries[index].key;
        }
    }
    return count;
}

st_index_t st_keys_check(
    st_table* table,
    st_data_t* keys,
    st_index_t size,
    st_data_t never)
{
    return st_keys(table, keys, size);
}

st_index_t st_values(
    st_table* table,
    st_data_t* values,
    st_index_t size)
{
    st_index_t count = 0;
    foreach (st_index_t index; table.entries_start .. table.entries_bound)
    {
        if (table.entries[index].hash != DELETED_HASH)
        {
            if (count == size)
                break;
            values[count++] = table.entries[index].record;
        }
    }
    return count;
}

st_index_t st_values_check(
    st_table* table,
    st_data_t* values,
    st_index_t size,
    st_data_t never)
{
    return st_values(table, values, size);
}

void st_free_table(st_table* table)
{
    if (table is null)
        return;
    rpmalloc_heap_t* heap = table.heap;
    rpmalloc_heap_free(heap, table.entries);
    rpmalloc_heap_free(heap, table);
}

int st_numcmp(st_data_t left, st_data_t right)
{
    return numeric_compare(left, right);
}

int st_locale_insensitive_strncasecmp(
    const(char)* left,
    const(char)* right,
    size_t count)
{
    foreach (size_t index; 0 .. count)
    {
        ubyte left_value = ascii_lower(cast(ubyte) left[index]);
        ubyte right_value = ascii_lower(cast(ubyte) right[index]);
        if (left_value != right_value)
            return left_value > right_value ? 1 : -1;
        if (left_value == 0)
            return 0;
    }
    return 0;
}

int st_locale_insensitive_strcasecmp(
    const(char)* left,
    const(char)* right)
{
    size_t left_length = strlen(left);
    size_t right_length = strlen(right);
    size_t count =
        left_length > right_length ? left_length : right_length;
    return st_locale_insensitive_strncasecmp(
        left,
        right,
        count + 1);
}

st_index_t st_numhash(st_data_t value)
{
    return numeric_hash(value);
}

private enum st_index_t MURMUR_C1 =
    cast(st_index_t) 0x87c37b91114253d5UL;
private enum st_index_t MURMUR_C2 =
    cast(st_index_t) 0x4cf5ad432745937fUL;

private st_index_t rotate_left(st_index_t value, uint count)
{
    return value << count |
        value >> (st_index_t.sizeof * 8 - count);
}

private st_index_t murmur_step(st_index_t hash, st_index_t key)
{
    key *= MURMUR_C1;
    hash ^= rotate_left(key, 33);
    hash *= MURMUR_C2;
    hash = rotate_left(hash, 24);
    return hash;
}

private st_index_t murmur_finish(st_index_t hash)
{
    /*
     * Values are taken from Mix13:
     * http://zimbry.blogspot.ru/2011/09/better-bit-mixing-improving-on.html
     */
    hash ^= hash >> 30;
    hash *= cast(st_index_t) 0xbf58476d1ce4e5b9UL;
    hash ^= hash >> 27;
    hash *= cast(st_index_t) 0x94d049bb133111ebUL;
    hash ^= hash >> 31;
    return hash;
}

st_index_t st_hash(
    const(void)* pointer,
    size_t length,
    st_index_t seed)
{
    /*
     * This hash function is a simplified MurmurHash3. Simplification is
     * effective because most of the mixing happens in the finalizer.
     */
    const(ubyte)* data = cast(const(ubyte)*) pointer;
    st_index_t hash = seed;
    size_t remaining = length;

    while (remaining >= st_index_t.sizeof)
    {
        st_index_t word = 0;
        foreach (size_t index; 0 .. st_index_t.sizeof)
            word |= cast(st_index_t) data[index] << (index * 8);
        hash = murmur_step(hash, word);
        data += st_index_t.sizeof;
        remaining -= st_index_t.sizeof;
    }

    st_index_t tail = 0;
    foreach (size_t index; 0 .. remaining)
        tail |= cast(st_index_t) data[index] << (index * 8);
    if (remaining != 0)
    {
        hash ^= tail;
        hash -= rotate_left(tail, 7);
        hash *= MURMUR_C2;
    }
    hash ^= length;
    return murmur_finish(hash);
}

st_index_t st_hash_start(st_index_t value)
{
    return value;
}

st_index_t st_hash_uint32(st_index_t hash, uint value)
{
    return murmur_step(hash, value);
}

st_index_t st_hash_uint(st_index_t hash, st_index_t value)
{
    value += hash;
    return murmur_step(hash, value);
}

st_index_t st_hash_end(st_index_t hash)
{
    return murmur_finish(hash);
}
