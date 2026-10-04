# Arena-backed arrays: laserd.array

`laserd.array` provides `Array!T`, a growable array with indexed access,
ranges, insertion, replacement, removal, and duplication.

Each usable array borrows a non-null [Arena](memory.md). Copies share contents;
`dup()` creates independent array storage in the same arena. Keep the arena
alive until every copy and range is finished, then call `destroy()` once.
This is a Laser-D-specific API, not a Phobos compatibility module.

## Types and construction

```d
struct Array(T) if (!is(immutable T == immutable bool))
{
    this(Arena* arena);
    this(Arena* arena, T[] values);
    struct Range; // A view into the shared array state.
}
```

The arena must be non-null and outlive all arrays and ranges. Constructors and
`dup` require their allocations to succeed; they do not return a recoverable
allocation status. A default `Array!T.init` is uninitialized. Construct an
array before using mutators or
`dup`. `Array!bool` is excluded.

## Array methods

```d
bool initialized();
bool empty();
size_t length();
size_t capacity();
size_t opDollar();
Arena* arena();
T[] data();
bool reserve(size_t elements);
bool resize(size_t newLength);
T opIndex(size_t index);
void opIndexAssign(T value, size_t index);
T front();
T back();
Range opSlice();
Range opSlice(size_t begin, size_t end);
void opSliceAssign(T value);
void opSliceAssign(T value, size_t begin, size_t end);
size_t insertBack(T value);
size_t insertBack(T[] values);
alias insert = insertBack;
void opOpAssign(string operation)(T value) if (operation == "~");
void opOpAssign(string operation)(T[] values) if (operation == "~");
size_t insertBefore(Range range, T value);
alias stableInsertBefore = insertBefore;
size_t insertAfter(Range range, T value);
T removeAny();
alias stableRemoveAny = removeAny;
void removeBack();
size_t removeBack(size_t howMany);
alias stableRemoveBack = removeBack;
Range linearRemove(Range range);
alias stableLinearRemove = linearRemove;
size_t replace(Range range, T value);
Array dup();
bool opEquals(ref Array rhs);
void clear();
void destroy();
```

| Operations | Contract |
| --- | --- |
| Accessors | `data` borrows the used storage; indexing/front/back return values. Indexes and slices must be in bounds; front/back require nonempty arrays. |
| `reserve`, `resize` | Return false when growth fails or the array is uninitialized. Reserve changes capacity only; resize changes logical length. Newly allocated bytes are zeroed, but shrinking and regrowing within capacity can expose previous contents. |
| `insertBack`, `insert`, `insertBefore`, `insertAfter` | Return inserted element count, or zero on allocation failure/empty input. Positional ranges must belong to this array. Before uses the range start; after uses its end. |
| `~=` | Calls insertion but discards its status; use `insertBack` when failure must be checked. |
| `removeAny`, `removeBack` | Remove from the tail; `removeAny` returns the removed value. Counted removal clamps to length and returns the removed count. |
| `linearRemove` | Removes the range, shifts the tail, and returns a range from the removal position to the new end. |
| `replace` | Replaces a nonempty range with one value, or inserts into an empty range; returns one on success or zero on growth failure. |
| `dup`, equality | Duplicate storage in the same arena; compare element values. Duplication does not deep-copy objects referenced by elements. |
| `clear`, `destroy` | Clear releases payload and retains shared state for reuse. Destroy also releases state and invalidates every shared copy/range. Call destroy once. |

The `stable*` names are aliases, not additional storage-stability guarantees.
Growth may invalidate raw slices/pointers from `data`. Insertion and removal
can change the elements selected by a range or invalidate the range. Obtain
fresh ranges after structural changes.

## Range methods

```d
bool empty();
size_t length();
alias opDollar = length;
T front();
T back();
void popFront();
void popBack();
Range save();
T opIndex(size_t index);
void opIndexAssign(T value, size_t index);
Range opSlice();
Range opSlice(size_t begin, size_t end);
void opSliceAssign(T value);
```

Range indexing is relative to its start. `save` copies the view, not payload;
pop operations move only the view's endpoints. Assignment updates shared
elements. Range front/back/pop operations require a nonempty view.

## Using the library

Uses [Arena](memory.md); link `laserd_rpmalloc`
and its platform dependencies and initialize the allocator first.

## Implementation Details

Source: `library/laserd/array.d`.

Integration coverage: `library/test/container_array.d` (CTest `container_array`).

The array began as a port of Phobos's array container. Each array holds a
pointer to shared state containing its arena, storage, and used length. Ranges
hold the same state pointer and a pair of indices. Constructors and `dup`
express allocation-success preconditions with assertions. A packed Boolean
specialization remains deferred.
