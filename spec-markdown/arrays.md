# Arrays and slices

Laser-D has fixed-size arrays and non-owning slices.

| Syntax | Meaning |
| --- | --- |
| `T[n]` | inline storage containing `n` values of type `T` |
| `T[]` | pointer-and-length view of values of type `T` |
| `T*` | pointer with no associated length |

A fixed array contains its elements. A slice refers to storage managed
elsewhere and does not extend that storage's lifetime.

## <a id="static-arrays"></a>Fixed-size arrays

```text
FixedArrayType:
    Type [ CompileTimeIntegralExpression ]
```

The element type and dimension are part of the fixed-array type:

```d
int fixedArrayLength()
{
    int[4] values;
    static assert(is(typeof(values) == int[4]));
    return values.length;
}

static assert(fixedArrayLength() == 4);
```

The dimension is an integral expression evaluated at compile time. Integer
literals are supported. Support for equivalent manifest-constant expressions
has a recorded implementation defect in
[Feature status](../FEATURE_STATUS.md).

A fixed array stores its elements inline. It may be a local variable, a field,
an element of another fixed array, a function parameter or result, or part of
deeply immutable static storage.

Fixed arrays have value semantics. Assignment, argument passing, and return copy
the element values into the destination array storage.

### Nested fixed arrays

A multidimensional fixed array is an array whose element type is another fixed
array:

```d
int matrixElement()
{
    int[3][2] matrix;
    matrix[1][2] = 7;
    return matrix[1][2];
}
```

`matrix` contains two `int[3]` rows in rectangular inline storage. A slice of
`matrix` views its outer `int[3]` elements.

## <a id="dynamic-arrays"></a>Non-owning slices

```text
SliceType:
    Type []
```

A slice contains:

- a pointer to its first element; and
- a number of elements.

```d
int sliceExample()
{
    int[4] storage;
    int[] whole = storage[];
    int[] middle = storage[1 .. 3];
    middle[0] = 42;
    static assert(is(typeof(middle) == int[]));
    return whole[1];
}
```

`whole` and `middle` refer to `storage`. Writing through `middle` changes the
same element observed through `whole`.

Multiple slices may refer to the same elements. Copying a slice value copies
only its pointer and length.

A default-initialized or explicitly null slice has length zero and a null
pointer:

```d
bool isDefaultSliceNull()
{
    int[] values;
    return values.length == 0 && values.ptr is null;
}
```

The program ensures that referenced storage remains live for every use of the
slice.

## Initialization

### Default initialization

A fixed array's default initialization initializes each element from its
element type's `.init` value:

```d
int firstDefaultElement()
{
    int[4] values;
    return values[0];
}
```

A slice default-initializes to the null slice.

A context-typed array literal initializes fixed storage without allocation:

```d
int[5] values = [10, 14, 3, 5, 23];
```

The number of literal elements must match the fixed-array dimension. An array
literal whose resulting type remains `T[]`, including one inferred with
`auto`, is a dynamic array literal and is rejected.

### Void initialization

A local fixed array may use `void` initialization:

```d
int[4] values = void;
```

Each element is assigned a valid value before it is read.

### Fixed-array literals

An array literal initializes fixed destination storage when the complete target
shape is known:

```d
int[3] values = [1, 2, 3];
int[2][2] matrix = [[1, 2], [3, 4]];
```

Each initializer is converted to the corresponding element type and written
directly into the fixed array.

### Scalar initialization and filling

A compatible scalar initializer or full-slice assignment fills existing
elements:

```d
void clear(int[] values)
{
    values[] = 0;
}
```

No new backing storage is created.

### Static initialization

A fixed array in deeply immutable static storage has a compile-time initializer:

```d
immutable int[4] table = [1, 2, 3, 4];
```

String literals provide their own compiler-managed immutable static storage, as
described below.

## Indexing

Fixed arrays, slices, and pointers support indexing with an integral expression:

```d
int first(int[] values)
{
    return values[0];
}
```

Within a fixed-array or slice index, `$` is its current element count:

```d
int last(int[] values)
{
    return values[$ - 1];
}
```

For a fixed array or slice, a valid index is in the half-open range
`0 .. length`. Pointer indexing requires the pointer to address a valid element
range supplied by the program.

## Slicing

The expression `value[lower .. upper]` creates a non-owning view of a half-open
element range:

```d
int[] middle(int[] values)
{
    return values[1 .. $ - 1];
}
```

For a fixed array or slice, valid bounds satisfy:

```text
0 <= lower <= upper <= value.length
```

`value[]` selects the entire fixed array or slice.

A pointer can form a slice when the program supplies the bounds:

```d
import core.stdc.stddef : size_t;

int[] view(int* pointer, size_t count)
{
    return pointer[0 .. count];
}
```

The pointer must address at least `count` live, suitably aligned `int` objects.

Slicing does not copy elements.

## Properties

### `.length`

`.length` is the number of elements.

For a fixed array, it is a compile-time property determined by the type. For a
slice, it is the number of elements in the current view.

The property is read-only.

### `.ptr`

`.ptr` is a pointer to the first element:

```d
int* firstPointer(ref int[4] storage)
{
    int[] view = storage[];
    return view.ptr;
}
```

For a null slice, `.ptr` is null. Obtaining the pointer does not transfer
ownership or extend storage lifetime.

## Assignment to existing storage

Assigning one slice variable to another rebinds the destination view:

```d
void rebind(ref int[4] firstStorage, ref int[4] secondStorage)
{
    int[] destination = firstStorage[];
    destination = secondStorage[];
}
```

Assigning through full-slice expressions copies compatible POD element values
into existing destination storage:

```d
void copy(int[] destination, int[] source)
{
    destination[] = source[];
}
```

Source and destination have the same length. The operation changes neither
slice's pointer or length.

A full-slice scalar assignment fills the destination:

```d
void fill(int[] destination)
{
    destination[] = 0;
}
```

## Strings

A string literal is immutable compiler-managed static character storage.

| Literal | Element type |
| --- | --- |
| `"Laser-D"` | `immutable(char)` |
| `"Laser-D"w` | `immutable(wchar)` |
| `"Laser-D"d` | `immutable(dchar)` |

The literal is normally used through an immutable character slice:

```d
immutable(char)[] text = "Laser-D";
```

String slices may be indexed, sliced, passed, and returned:

```d
immutable(char)[] trim(immutable(char)[] value)
{
    return value[1 .. $ - 1];
}
```

Indexing operates on UTF-8, UTF-16, or UTF-32 code units according to the
element type. It does not implicitly decode, normalize, or transcode text.

Literal storage cannot be modified and does not implicitly convert to a mutable
character slice.

### String comparison

`==` and `!=` compare compatible character slices element by element:

```d
bool equal(immutable(char)[] left, immutable(char)[] right)
{
    return left == right;
}
```

`is` and `!is` compare the identity of the slice view:

```d
bool sameView(immutable(char)[] left, immutable(char)[] right)
{
    return left is right;
}
```

Identity compares the represented view rather than the character contents.

### Character pointers and C strings

A character pointer has no length and does not by itself establish
zero-termination:

```d
extern(C) int consume(const(char)* text);
```

C-string termination, encoding, ownership, and lifetime follow the foreign
API's contract.

## Conversions

A fixed array converts to a compatible slice by referencing its existing
elements:

```d
int[] asSlice(ref int[4] storage)
{
    return storage[];
}
```

The qualifier rules determine whether mutable or immutable element views are
compatible.

A slice exposes its element pointer through `.ptr`. A pointer becomes a slice
only through an explicit slice expression with bounds.

These conversions copy no elements and transfer no ownership.
