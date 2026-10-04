# Arena-backed arrays: laserd.array

Source: `library/laserd/array.d`. Uses [Arena](memory.md); link `laserd_rpmalloc`
and its platform dependencies and initialize the allocator first.

`laserd.array` provides Laser-D's arena-backed `Array!T`. It was initially
derived from Phobos's array container but is not a compatibility module. Every
usable array is constructed with a borrowed, non-null `Arena*`; copies
share state, while `dup()` creates independent payload storage in the same
arena. Call `destroy()` once after the last shared copy and range is finished.
The port covers indexed access and assignment, slicing/ranges, reserve/resize,
append and positional insertion, replacement, removal, duplication, and clear.
Its API uses explicit accessor methods suited to Laser-D's language subset,
and a packed boolean specialization remains deferred.

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
`dup` require their allocations to succeed (the implementation asserts this
precondition); they do not return a recoverable allocation status. A default
`Array!T.init` is uninitialized. Construct an array before using mutators or
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
Growth may invalidate raw slices/pointers from `data`. Ranges retain indices
into shared state; insertion/removal can change what those indices mean or
make them invalid. Obtain fresh ranges after structural changes.

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

Integration coverage: `library/test/container_array.d` (CTest `container_array`).
