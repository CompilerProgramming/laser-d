# Insertion-ordered hash tables: laserd.hash

Source: `library/laserd/hash.d`. Uses [Arena](memory.md); link `laserd_rpmalloc`
and its platform dependencies and initialize the allocator first.

The pure Laser-D module `laserd.hash` is an
insertion-ordered port of the public-domain `st` C hash table with machine-word
keys and values. It retains the original binless linear-search representation
for small tables, the packed 8/16/32/64-bit bin indices for larger tables, the
combined entries-and-bins allocation, probing sequence, and rebuild thresholds.
A fidelity test checks the original numeric, C-string, case-insensitive, and
incremental hash algorithms against vectors produced by the C source.
Comparison callbacks and iteration may rebuild the table; searches detect the
changed rebuild counter, discard cached entry locations, and retry.
A caller supplies and retains ownership of a `laserd.memory.Arena`; a table
uses that Arena for its own allocation and growth but never destroys it.
`st_free_table` releases table storage through the Arena, so immediate memory
reclamation depends on the selected backend; bump and fixed-region storage is
reclaimed when the caller destroys the Arena.
Numeric, C-string, and ASCII case-insensitive C-string policies are predefined,
and callers may supply compatible hash and comparison function pointers.
Allocation failure is returned as `null` from creation/copying and as
`ST_ERROR` from operations that may grow the table.

## Types, callbacks, and constants

```d
alias st_data_t = size_t;
alias st_index_t = size_t;

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
```

```d
struct st_hash_type
{
    st_compare_func compare;
    st_hash_func hash;
}
```

`st_table` stores the borrowed `Arena* arena`, policy pointer `type`, entry count
`num_entries`, and implementation bookkeeping (`entry_power`, `bin_power`,
`size_ind`, `entries_start`, `entries_bound`, `rebuilds_num`, `entries`). Use
functions below to manage it rather than modifying those fields. The entry
record type is private. The immutable policies `st_hashtype_num`,
`st_hashtype_str`, and `st_hashtype_strcase` are `st_hash_type` values.

Comparators return zero for equal keys; equal keys must have equal hashes.
Custom policy storage and any referenced keys/values must outlive their use
by the table. String keys are borrowed, zero-terminated C strings. Copying a
table does not duplicate the pointees of keys or values.

## Functions

```d
st_table* st_init_table(
    Arena* arena,
    const(st_hash_type)* type);
st_table* st_init_table_with_size(
    Arena* arena,
    const(st_hash_type)* type,
    st_index_t size);
st_table* st_init_numtable(Arena* arena);
st_table* st_init_numtable_with_size(
    Arena* arena,
    st_index_t size);
st_table* st_init_strtable(Arena* arena);
st_table* st_init_strtable_with_size(
    Arena* arena,
    st_index_t size);
st_table* st_init_strcasetable(Arena* arena);
st_table* st_init_strcasetable_with_size(
    Arena* arena,
    st_index_t size);
st_index_t st_table_size(const(st_table)* table);
size_t st_memsize(const(st_table)* table);
int st_lookup(st_table* table, st_data_t key, st_data_t* value);
int st_is_member(st_table* table, st_data_t key);
int st_get_key(st_table* table, st_data_t key, st_data_t* result);
int st_insert(st_table* table, st_data_t key, st_data_t value);
int st_insert2(
    st_table* table,
    st_data_t key,
    st_data_t value,
    st_insert_callback_func transform);
int st_add_direct(st_table* table, st_data_t key, st_data_t value);
int st_delete(st_table* table, st_data_t* key, st_data_t* value);
int st_delete_safe(
    st_table* table,
    st_data_t* key,
    st_data_t* value,
    st_data_t never);
void st_cleanup_safe(st_table* table, st_data_t never);
int st_shift(st_table* table, st_data_t* key, st_data_t* value);
void st_clear(st_table* table);
st_table* st_copy(st_table* old_table);
int st_update(
    st_table* table,
    st_data_t key,
    st_update_callback_func callback,
    st_data_t argument);
int st_foreach(
    st_table* table,
    st_foreach_callback_func callback,
    st_data_t argument);
int st_foreach_check(
    st_table* table,
    st_foreach_check_callback_func callback,
    st_data_t argument,
    st_data_t never);
int st_foreach_with_replace(
    st_table* table,
    st_foreach_check_callback_func callback,
    st_update_callback_func replace,
    st_data_t argument);
st_index_t st_keys(
    st_table* table,
    st_data_t* keys,
    st_index_t size);
st_index_t st_keys_check(
    st_table* table,
    st_data_t* keys,
    st_index_t size,
    st_data_t never);
st_index_t st_values(
    st_table* table,
    st_data_t* values,
    st_index_t size);
st_index_t st_values_check(
    st_table* table,
    st_data_t* values,
    st_index_t size,
    st_data_t never);
void st_free_table(st_table* table);
int st_numcmp(st_data_t left, st_data_t right);
int st_locale_insensitive_strncasecmp(
    const(char)* left,
    const(char)* right,
    size_t count);
int st_locale_insensitive_strcasecmp(
    const(char)* left,
    const(char)* right);
st_index_t st_numhash(st_data_t value);
st_index_t st_hash(
    const(void)* pointer,
    size_t length,
    st_index_t seed);
st_index_t st_hash_start(st_index_t value);
st_index_t st_hash_uint32(st_index_t hash, uint value);
st_index_t st_hash_uint(st_index_t hash, st_index_t value);
st_index_t st_hash_end(st_index_t hash);
```

| Group | Behavior |
| --- | --- |
| `st_init_table`, `st_init_table_with_size` | Create with a borrowed arena and custom policy; return null on failure. |
| `st_init_numtable*`, `st_init_strtable*`, `st_init_strcasetable*` | Create with numeric, C-string, or ASCII case-insensitive C-string policy; `_with_size` supplies an initial size hint. |
| `st_table_size`, `st_memsize` | Entry count and table storage byte count. |
| `st_lookup`, `st_is_member`, `st_get_key` | Return one if found, zero otherwise; lookup optionally writes a value, get-key writes the stored key. |
| `st_insert`, `st_insert2` | Return one when updating an existing key, zero for a new key, or `ST_ERROR` on growth failure. `st_insert2` transforms a newly inserted key through its callback. |
| `st_add_direct` | Append without duplicate lookup; caller must supply an absent key. Returns zero or `ST_ERROR`. |
| `st_delete`, `st_shift` | Return one when removed, zero if absent/empty; output removed key/value. Shift removes the oldest entry. |
| `st_delete_safe`, `st_cleanup_safe` | Compatibility entry points; `never` is unused, delete-safe delegates to delete, cleanup-safe does nothing. |
| `st_clear`, `st_free_table` | Clear retains table storage; free releases it through its arena without freeing keys/values or destroying the arena. |
| `st_copy` | Copy table storage into the same borrowed arena; returns null on failure. |
| `st_update` | Callback receives key/value pointers, argument, and existing flag; can stop, delete, update, or insert. Growth can return `ST_ERROR`. |
| `st_foreach*` | Iterate in insertion order. Callback actions control continuation, stopping, deletion, checking, or replacement as appropriate to the variant. |
| `st_keys*`, `st_values*` | Copy at most `size` entries into caller storage and return count; `_check` variants ignore `never`. |
| `st_numcmp`, `st_numhash` | Numeric policy primitives. |
| `st_locale_insensitive_strcasecmp`, `st_locale_insensitive_strncasecmp` | ASCII case-insensitive comparison, independent of locale. |
| `st_hash` | Hash `length` bytes with an initial value. |
| `st_hash_start`, `st_hash_uint32`, `st_hash_uint`, `st_hash_end` | Build an incremental hash from integer values. |

An update or replacement callback may change a key only to an equal key with
the same hash and must not rebuild the table. A detected rebuild in either of
these callbacks returns `ST_ERROR`. `st_update` returns one for an existing
entry and zero for an absent entry unless an error occurs.

Iteration callbacks receive the key, value, and caller argument. Checked
callbacks also receive an error flag, normally zero; if a rebuild loses the
current entry they are called with zero key/value and an error flag of one.
`ST_CONTINUE`/`ST_CHECK` continue, `ST_STOP` stops, and `ST_DELETE` removes the
current entry. Only `st_foreach_with_replace` accepts `ST_REPLACE`, invoking its
replacement callback on key/value pointers. Iteration returns zero on normal
completion or stop, one for a check/action error, or `ST_ERROR` for a forbidden
replacement-callback rebuild.

Integration coverage: `library/test/hash.d` (CTest `hash_table`), including
vectors from the original C algorithms and callback-driven rebuilds.
