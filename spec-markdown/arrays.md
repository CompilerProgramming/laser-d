---
title: Arrays
status: restricted
source: ../spec/arrays.dd
---

# Arrays

This chapter defines Laser-D fixed-size arrays, non-owning slices, pointer
ranges, and string storage. Associative arrays are not part of Laser-D and are
specified only as a rejected feature in the associative-array chapter.

## <a id="array-kinds"></a>Array Kinds

| Syntax | Meaning |
| --- | --- |
| `T[n]` | Fixed-size inline array containing `n` values |
| `T[]` | Non-owning pointer-and-length slice |
| `T*` | Pointer to one or more externally managed values |

> **Laser-D normative:**
>
> Fixed arrays and slices are value types. A fixed array owns
> its inline elements. A slice owns no elements and carries no allocation or
> lifetime management. The program is responsible for ensuring that a slice's
> backing storage remains alive.

### <a id="static-arrays"></a>Fixed-Size Arrays

A fixed-array dimension is an integral compile-time expression. Its element
type and dimension form part of its type.

```d
d
int[4] values;
static assert(values.length == 4);
static assert(is(typeof(values) == int[4]));

```

Fixed arrays provide inline storage in local variables, permitted static
storage, and containing aggregates. They are copied, passed, and returned by
value. A zero-length fixed array is permitted. An array whose total size cannot
be represented by the target object format is rejected.

### <a id="dynamic-arrays"></a>Non-Owning Slices

The D syntax `T[]` denotes a Laser-D slice containing a pointer and a
length. A null slice has length zero and a null pointer. Multiple slices may
refer to the same storage.

```d
d
int[4] storage;
int[] all = storage[];
int[] middle = storage[1 .. 3];

```

> **Rejected in Laser-D:**
>
> A slice is not a GC-backed dynamic container. No Laser-D
> operation implicitly allocates backing storage, changes its capacity, or
> extends its lifetime.

### <a id="pointers"></a>Pointer Ranges

A pointer has no associated length. Pointer arithmetic, indexing, and
forming a slice from a pointer range are supported systems operations. The
program must ensure that the addressed range is valid.

```d
d
int[] view(int* pointer, size_t count)
{
    return pointer[0 .. count];
}

```

## <a id="declarations"></a>Array Declarations

```text
FixedArrayType:
    Type [ Expression ]

SliceType:
    Type []
```

Array declarators may be nested. In `int[3][2]`, the variable contains
two elements, each of which is an `int[3]`.

## <a id="literals"></a>Array Initializers and Literals

> **Laser-D normative:**
>
> An array literal may initialize fixed storage when its target
> fixed-array type and dimensions are known from the declaration. The values are
> materialized directly in that storage and do not imply allocation.

```d
int[3] values = [1
2
3];
int[2][2] matrix = [[1
2]
[3
4]];
```

A dimension written as `$` may be inferred from such an initializer when
the complete fixed-array shape is unambiguous.

> **Rejected in Laser-D:**
>
> An array literal without a fixed-storage target is a dynamic
> array literal and is not supported. In particular, `auto values = [1, 2, 3]` is rejected. Associative-array literals are also rejected.

## <a id="indexing"></a>Indexing

Fixed arrays, slices, and pointers support indexing with an integral
expression. For fixed arrays and slices, `$` denotes the current array or
slice length within an index expression.

```d
d
int last(int[] values)
{
    return values[$ - 1];
}

```

Indexing a fixed array or slice is bounds checked according to the selected
compiler bounds-checking mode. Pointer indexing is unchecked and requires the
program to provide a valid address.

### <a id="pointer-arithmetic"></a>Pointer Arithmetic

Addition and subtraction of an integral offset are supported for pointers.
Subtracting pointers into the same allocation produces their element distance.
The behavior is invalid when pointer arithmetic or dereferencing leaves the
underlying allocation.

## <a id="slicing"></a>Slicing

A slice expression `value[lower .. upper]` creates a non-owning view of
the half-open range from `lower` through `upper`. It does not copy
elements. Omitting both bounds with `value[]` selects the complete fixed
array or slice.

```d
d
int[] middle(int[] values)
{
    return values[1 .. $ - 1];
}

```

The bounds must satisfy `0 <= lower <= upper <= value.length` for fixed
arrays and slices. Pointer slicing relies on the program to supply a valid
range.

### <a id="array-length"></a>Array Length

The `.length` property is read-only. A fixed array's length is a
compile-time value. A slice's length is the number of elements in its current
view.

> **Rejected in Laser-D:**
>
> Assignment to slice `.length` is rejected because D uses it
> as a resizing operation. Laser-D slices cannot resize their backing storage.

## <a id="assignment"></a>Assignment and Existing Storage

### <a id="static-array-assign"></a>Fixed-Array Assignment

Compatible fixed arrays may be assigned by value. Every element is copied
into the destination's inline storage.

### <a id="array-copying"></a>Slice Copying

Slice assignment without brackets rebinds the slice value. Slice assignment
with brackets copies values into existing destination storage.

```d
d
void copy(int[] destination, int[] source)
{
    destination[] = source[];
}

```

Source and destination lengths must match. Element copying is supported
only when the element operation itself is supported by Laser-D. The operation
does not allocate.

#### <a id="overlapping-copying"></a>Overlapping Copying

Overlapping slices of the same element type are copied with overlap-safe
semantics. This does not extend the lifetime of either slice.

### <a id="array-setting"></a>Array Filling

Assigning one value to a full fixed array or slice fills the existing
elements.

```d
d
void clear(int[] values)
{
    values[] = 0;
}

```

## <a id="comparison"></a>Array and Slice Comparison

`is` and `!is` compare slice identity. `==` and `!=` compare
supported array or slice values element by element. Character-array equality
is supported when both operands have compatible element types.

> **Rejected in Laser-D:**
>
> Ordered comparisons `<`, `<=`, `>`, and `>=` on
> arrays or slices are rejected because upstream D lowers them through the
> unavailable D runtime `object.__cmp` hook.

## <a id="rejected-owning-operations"></a>Rejected Owning Operations

> **Rejected in Laser-D:**
>
> The following D array operations are not part of Laser-D:
>
>
> - array allocation with `new`;
> - dynamic array literals;
> - concatenation with `~` or `~=`;
> - duplication through `.dup` or `.idup`;
> - capacity inspection or reservation through `.capacity` or `.reserve`;
> - resizing by assigning `.length`; and
> - library or compiler behavior that assumes garbage-collected array ownership.

## <a id="array-operations"></a>Element-Wise Operations

Explicit loops and supported slice filling or copying operate on existing
storage. D's broader vectorized array-expression surface is not implied by
support for slices and remains outside the normative Laser-D array feature set
unless separately reviewed.

## <a id="rectangular-arrays"></a>Rectangular Fixed Arrays

Multidimensional fixed arrays are arrays whose elements are themselves
fixed arrays. Their layout is inline and rectangular.

```d
d
int[3][2] matrix;
matrix[1][2] = 7;

```

A slice of a multidimensional fixed array views its outer elements. Each
element retains its complete inner fixed-array type.

## <a id="array-properties"></a>Array and Slice Properties

### <a id="length-property"></a>`.length` Property

Read-only `.length` is supported for fixed arrays and slices. Writes to
slice `.length` are rejected.

### <a id="ptr-property"></a>`.ptr` Property

`.ptr` returns a pointer to the first element. For an empty or null
slice, the pointer may be null. Obtaining a pointer does not transfer ownership
or extend storage lifetime.

### <a id="func-as-property"></a>Functions as Array Properties

> **Rejected in Laser-D:**
>
> `.dup`, `.idup`, `.capacity`, and `.reserve` are
> rejected. User-defined property syntax is rejected by the general Laser-D
> attribute and call rules.

## <a id="bounds"></a>Bounds Checking

Fixed-array and slice indexing and slicing use the compiler's bounds checks.
Failure handling cannot depend on the D runtime in Laser-D builds. The precise
runtime-free failure mechanism and command-line bounds-checking policy remain a
separate implementation and portability concern.

### <a id="disable-bounds-check"></a>Bounds-Check Configuration

Compiler switches may alter generated bounds checks only where accepted by
the Laser-D command-line policy. They do not make an otherwise invalid pointer
or slice operation valid.

## <a id="array-initialization"></a>Array Initialization

### <a id="default-initialization"></a>Default Initialization

A normally declared fixed array initializes each element using the
element type's supported default initialization. A slice default-initializes to
the null slice.

### <a id="void-initialization"></a>Void Initialization

Explicit `void` initialization follows the general Laser-D variable
initialization rules and leaves elements uninitialized. Reading an element
before it has been initialized is invalid.

### <a id="array-initializers"></a>Fixed-Array Initializers

A fixed-array initializer may provide element values directly or use a
supported scalar fill. Nested initializers must match the complete rectangular
shape. Conversion of every initializer value to the element type must be
valid.

### <a id="static-init-static"></a>Static Storage Initialization

A fixed array in permitted static storage must have an initializer that is
valid for static initialization. Laser-D's restrictions on mutable global and
static storage apply independently.

#### <a id="static-string"></a>String Literal Initializers

Character fixed arrays and immutable character slices may be initialized
from compatible string literals. String literal storage is compiler-provided
static storage.

## <a id="special-array"></a>Character Arrays and Strings

### <a id="strings"></a>Strings

Laser-D has no distinct owning string type. A string literal is immutable
static character storage and is normally viewed through `immutable(char)[]`, `immutable(wchar)[]`, or `immutable(dchar)[]`. The conventional names
`string`, `wstring`, and `dstring` are library aliases rather than
intrinsic language types.

#### <a id="string-literal-types"></a>String Literal Types

String suffixes and character width follow the lexical specification.
String literals may be indexed, sliced, passed, returned, and compared for
supported equality without allocation. Their elements cannot be mutated, and
they do not implicitly convert to mutable character slices.

#### <a id="strings_unicode"></a>Unicode

`char`, `wchar`, and `dchar` retain D's UTF-8, UTF-16, and UTF-32
code-unit meanings. Indexing operates on code units. Laser-D does not imply an
allocating Unicode decoding or transcoding operation.

#### <a id="char-pointers"></a>Character Pointers and C Strings

A character pointer has no length and is not inherently zero-terminated.
C-string conventions are available through explicit C interoperability. The
program must validate termination and storage lifetime.

### <a id="void_arrays"></a>Void Slices

`void[]` may represent an untyped non-owning byte extent for systems and
C interoperability. It carries no element ownership and may be converted only
where the ordinary Laser-D conversion rules permit.

## <a id="implicit-conversions"></a>Conversions

A fixed array converts to a slice of compatible element type by referencing
its existing storage. Mutable storage may be viewed through a transitively
immutable-compatible type only where the general qualifier rules permit; an
immutable string literal never converts implicitly to a mutable slice.

A slice-to-pointer conversion uses `.ptr` explicitly. Pointer-to-slice
conversion requires an explicit pointer slice with bounds. These conversions
do not allocate or transfer ownership.

## <a id="conformance"></a>Conformance Boundary

Laser-D array conformance requires positive coverage for fixed storage, non-owning views, indexing, slicing, copying, filling, strings, and supported
comparisons, together with negative coverage for every rejected owning or
runtime-dependent operation. A D array feature not specified in this chapter
is not implied merely because upstream D accepts it.
