---
title: Types
status: restricted
source: ../spec/type.dd
---

# Types

> **Laser-D normative:**
>
> Laser-D is statically typed. Every expression has a type, and every type has a compile-time-known size and representation except
> `void`, opaque enums awaiting definition, and incomplete ImportC types.
> The language has no runtime type-information requirement.

## <a id="grammar"></a>Grammar

```text
Type:
    TypeCtors[] BasicType TypeSuffixes[]

TypeCtors:
    TypeCtor
    TypeCtor TypeCtors

TypeCtor:
    const
    immutable

BasicType:
    FundamentalType
    . QualifiedIdentifier
    QualifiedIdentifier
    Typeof
    Typeof . QualifiedIdentifier
    TypeCtor ( Type )
    TraitsExpression

FundamentalType:
    void
    ArithmeticType

ArithmeticType:
    bool
    byte
    ubyte
    short
    ushort
    int
    uint
    long
    ulong
    char
    wchar
    dchar
    float
    double

TypeSuffixes:
    TypeSuffix TypeSuffixes[]

TypeSuffix:
    *
    [ ]
    [ AssignExpression ]
    [ AssignExpression .. AssignExpression ]
    delegate Parameters
    function Parameters

QualifiedIdentifier:
    Identifier
    Identifier . QualifiedIdentifier
    TemplateInstance
    TemplateInstance . QualifiedIdentifier
    Identifier [ AssignExpression ]
    Identifier [ AssignExpression ] QualifiedIdentifier
```

A bracket suffix with no expression forms a non-owning slice. A suffix
with one compile-time expression forms a fixed-size array, or indexes a
compile-time type sequence where that interpretation applies. The range form
slices a compile-time type sequence.

> **Excluded from Laser-D:**
>
> A bracket suffix containing a type would form a D associative
> array and is not in the grammar. Vector and string-mixin types are also omitted.
> Function and delegate attributes are implicit or are specified on parameters as
> defined by the functions chapter.

## <a id="Basic Data Types"></a>Fundamental Types

| Type | `.init` | Meaning |
| --- | --- | --- |
| [`void`](#void) | no value | function with no result |
| [`bool`](#bool) | `false` | Boolean |
| `byte` | `0` | signed 8-bit integer |
| `ubyte` | `0u` | unsigned 8-bit integer |
| `short` | `0` | signed 16-bit integer |
| `ushort` | `0u` | unsigned 16-bit integer |
| `int` | `0` | signed 32-bit integer |
| `uint` | `0u` | unsigned 32-bit integer |
| `long` | `0L` | signed 64-bit integer |
| `ulong` | `0uL` | unsigned 64-bit integer |
| `float` | `float.nan` | IEEE-754 binary32 |
| `double` | `double.nan` | IEEE-754 binary64 |
| `char` | `'\xFF'` | UTF-8 code unit |
| `wchar` | `'\uFFFF'` | UTF-16 code unit |
| `dchar` | `'\U0000FFFF'` | UTF-32 code unit |
| `typeof(null)` | `null` | null-literal type |
| [`noreturn`](#noreturn) | no value | bottom type |

Integer representation, alignment, and byte order follow the target ABI.
The supported initial targets use two's-complement integers. Character types
are distinct unsigned integral types; their values are code units and are not
automatically validated as complete Unicode scalar values.

> **Excluded from Laser-D:**
>
> `real`, `cent`, `ucent`, `ifloat`, `idouble`, `ireal`, `cfloat`, `cdouble`, and `creal` are not
> Laser-D types. ImportC may retain internal representations required for C
> `long double` and other C declarations.

### <a id="void"></a>`void`

`void` denotes the absence of a value. It is valid as a function result
and as the target of a pointer, but an object or parameter cannot have type
`void`. A `void*` may point to storage of any object type.

### <a id="bool"></a>`bool`

`bool` has the values `false` and `true`. Converting zero or a null
pointer to `bool` yields `false`; converting any other supported scalar
value yields `true`. Converting `bool` to an integer yields zero or one.

## <a id="Derived Data Types"></a>Derived Types

- [Pointers](#pointers)
- [Fixed-size arrays](arrays.md#static-arrays)
- [Non-owning slices](arrays.md#dynamic-arrays)
- [Function pointers](#function-pointers)
- [Restricted delegates](#delegates)
- [Immutable types](const3.md)
- Compile-time type sequences produced by templates

### <a id="component-types"></a>Component Types

A pointer, fixed array, or slice has an element or pointed-to component
type. A function type has a result type and parameter types. A delegate has the
same function signature plus a context pointer. Applying `immutable` to a
compound value is transitive through all of its stored components.

### <a id="pointers"></a>Pointers

A value of type `T*` is either `null` or an address interpreted as
pointing to a `T`. Pointer validity, alignment, provenance, object lifetime, and bounds are programmer responsibilities. Dereferencing an invalid pointer
has undefined behavior.

```d
int value = 3;
int* pointer = &value;
*pointer = 4;
```

Pointers provide explicit access to external allocation and C APIs. Laser-D
does not associate ownership or garbage collection with a pointer.

## <a id="User Defined Types"></a>User-Defined Types

Laser-D user-defined runtime value types are structs, unions, and enums.
Templates may generate or transform any supported type. Aliases introduce
another name for a type but do not create a distinct type.

> **Excluded from Laser-D:**
>
> Native D classes and interfaces, C++ structs and classes, COM
> interfaces, and Objective-C object types cannot be declared by Laser-D source.
> ImportC retains C struct, union, enum, and incomplete types.

## <a id="type-conversions"></a>Type Conversions

A conversion is permitted only when both source and destination types are
supported. No conversion may introduce allocation, runtime type information, class dispatch, or a rejected qualifier.

### <a id="Implicit Conversions"></a>Implicit Conversions

- Integral values may widen to a type that represents their complete value range.
- Compile-time constants may convert to an integral type when the value is representable.
- `float` may convert to `double`.
- A pointer may convert to `void*` while preserving qualification.
- `null` may convert to a pointer, slice, function pointer, or delegate.
- Fixed arrays, slices, function pointers, and delegates use the conversion rules in their dedicated chapters.

Other numeric narrowing and reinterpretation requires an explicit cast.
An explicit cast still cannot name or produce an excluded Laser-D type.

### <a id="Pointer Conversions"></a>Pointer Conversions

A pointer to an object type implicitly converts to `void*`. Converting a
`void*` back to another pointer type requires an explicit cast. Conversion
does not adjust alignment, extend lifetime, or establish that the destination
object exists.

### <a id="Integer Promotions"></a>Integer Promotions

Integer promotions used by arithmetic convert `bool`, `byte`, `ubyte`, `short`, `ushort`, `char`, and `wchar` to `int`.
`dchar` promotes to `uint`. Larger integer types retain their rank.

### <a id="Usual Arithmetic Conversions"></a>Arithmetic Conversions

Binary arithmetic first applies integer promotion. If either operand is
`double`, the other numeric operand converts to `double`; otherwise if
either operand is `float`, the other converts to `float`. Integral
operands then convert to the common signed or unsigned type determined by their
rank and representable range.

Arithmetic never promotes to `real`, imaginary, complex, or vector
types. Enum arithmetic is limited by the enum rules.

### <a id="enum-ops"></a>Enum Operations

Enum values retain their enum type except where the enum chapter permits
conversion to or from the base type. Unsupported automatic numbering or
arithmetic is diagnosed at compile time.

### <a id="covariance"></a>Function Type Compatibility

Function pointers and delegates are compatible only when their calling
convention, parameter passing, and result types satisfy the functions chapter.
Laser-D has no class covariance and rejects reference results.

## <a id="functions"></a>Function Types

```text
FunctionType:
    Type function Parameters
    Type delegate Parameters
```

Every function type is implicitly `nothrow`, `@nogc`, and
`@system`. These attributes cannot be written explicitly. Function types
are conservatively impure. Parameters may use only the annotations allowed by
the functions chapter, and results are returned by value.

### <a id="function-pointers"></a>Function Pointers

A function pointer contains a code address and no context. A null function
pointer cannot be called.

```d
int addOne(int value) { return value + 1; }
int function(int) operation = &addOne;
```

### <a id="delegates"></a>Delegates

A delegate contains a function pointer and a context pointer. Laser-D
supports delegates bound to struct methods and delegate values whose context
does not capture an enclosing local variable. The value itself is fixed-size
and does not allocate.

> **Excluded from Laser-D:**
>
> A delegate literal or nested function that captures an
> enclosing local variable is rejected, regardless of whether D could place its
> closure on the stack or heap.

## <a id="typeof"></a>`typeof`

```text
Typeof:
    typeof ( Expression )
    typeof ( return )
```

`typeof(expression)` yields the compile-time type of an expression
without evaluating it. `typeof(return)` yields the current function's result
type. The resulting type remains subject to all Laser-D restrictions.

### <a id="typeof-this"></a>`typeof(this)`

Inside a struct or union, `typeof(this)` denotes the containing aggregate
type. Laser-D has no class inheritance, and `typeof(super)` is rejected.

## <a id="runtime_type_information"></a>No Runtime Type Information

> **Excluded from Laser-D:**
>
> Laser-D does not generate or expose `TypeInfo`, class
> metadata, or runtime type identifiers. Compile-time operations such as
> `typeof`, `is`, templates, and supported `__traits` queries inspect
> frontend types without requiring runtime metadata.

## <a id="mixin_types"></a>String Mixin Types

> **Excluded from Laser-D:**
>
> String mixin types are not part of Laser-D. Template mixins
> operate on parsed declarations and remain available under their own chapter.

## <a id="aliased-types"></a>Conventional Type Aliases

### <a id="size_t"></a>`size_t`

`size_t` is the unsigned integer type capable of representing the size
of any addressable object. Its concrete fundamental type is target-dependent.

### <a id="ptrdiff_t"></a>`ptrdiff_t`

`ptrdiff_t` is the signed integer type corresponding in width to
`size_t`. Its concrete fundamental type is target-dependent.

### <a id="string"></a>Character Slice Aliases

`string`, `wstring`, and `dstring` are
conventional aliases for immutable character slices normally supplied by
`object.d`. They are not owning string types.

### <a id="noreturn"></a>`noreturn`

`noreturn`, defined as `typeof(*null)`, is the bottom type. No value
of this type is produced, and it implicitly converts to any result type. A
function inferred never to return may have this result type without requiring
exception support.
