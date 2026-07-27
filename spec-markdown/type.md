---
title: Types
status: restricted
source: ../spec/type.dd
---

# Types

Laser-D is statically typed. Every expression has a compile-time type. Every
complete object type has a compile-time-known size, alignment, and
representation.

`void` represents the absence of a value. An opaque enum has no complete
representation until its definition is available. ImportC may also introduce
an incomplete C type which can be named and pointed to but not instantiated.

## Type grammar

```text
Type:
    TypeCtor* BasicType TypeSuffix*

TypeCtor:
    const
    immutable

BasicType:
    FundamentalType
    QualifiedIdentifier
    . QualifiedIdentifier
    typeof ( Expression )
    typeof ( return )
    TypeCtor ( Type )
    TraitsExpression

FundamentalType:
    void
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

TypeSuffix:
    *
    [ ]
    [ AssignExpression ]
    [ AssignExpression .. AssignExpression ]
    function Parameters
    delegate Parameters

QualifiedIdentifier:
    Identifier
    Identifier . QualifiedIdentifier
    TemplateInstance
    TemplateInstance . QualifiedIdentifier
```

A `*` suffix forms a pointer. An empty bracket suffix forms a non-owning
slice. A bracket suffix containing one compile-time expression forms a
fixed-size array. In template type-sequence contexts, bracket expressions may
instead index or slice the sequence.

Function and delegate suffixes form callable types as defined in the functions
chapter.

## <a id="basic-data-types"></a>Fundamental types

| Type | `.init` | Meaning |
| --- | --- | --- |
| `void` | no value | absence of a function result |
| `bool` | `false` | Boolean |
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

Integer size and signedness are fixed by the table. Alignment and byte order
follow the target ABI. The supported x86-64 targets use two's-complement
integers.

Character types are distinct unsigned integral types. Their values are code
units; storing a value does not by itself validate a complete Unicode scalar
value or encoded sequence.

### `void`

`void` is valid as a function result and as the pointed-to type of `void*`. A
variable, field, or parameter does not have type `void`.

A `void*` can hold the address of any object. Its value carries no type,
alignment, size, ownership, or lifetime guarantee for the referenced storage.

### `bool`

`bool` has the values `false` and `true`.

Converting zero or a null pointer to `bool` produces `false`. Converting another
scalar value to `bool` produces `true`. Converting a `bool` to an integer
produces zero or one.

### Null type

The `null` literal has the distinct compile-time type `typeof(null)`. It can
initialize a pointer, slice, function pointer, or delegate:

```d
int* pointer = null;
int[] view = null;
int function(int) operation = null;
int delegate(int) callback = null;
```

## Derived types

Laser-D derives:

- pointers;
- fixed-size arrays;
- non-owning slices;
- function pointers;
- delegates;
- `const` and `immutable` qualified types; and
- compile-time type sequences produced by templates.

The arrays, qualifiers, functions, and templates chapters define their detailed
rules.

### Component types

A pointer, fixed array, or slice has a component type. A function pointer has a
result type, parameter types, and calling convention. A delegate has the same
callable signature plus a context pointer.

Applying `immutable` to a compound value is transitive through all stored
components. `const` provides a read-only view according to the qualifier rules.

### Pointers

A value of type `T*` is either `null` or an address interpreted as pointing to
a `T` object.

```d
int value = 3;
int* pointer = &value;
*pointer = 4;
```

Pointer validity, alignment, provenance, object lifetime, and bounds are
programmer responsibilities. Dereferencing a pointer is valid only while it
addresses a suitably aligned live object of a compatible type.

A pointer has no implicit ownership. Explicit foreign allocation APIs may
return pointers whose release requirements are defined by that API.

## User-defined value types

Laser-D user-defined runtime types are:

- structs;
- unions; and
- enums.

Structs and unions define fixed-layout value storage. Enums define a named
integral value domain. Their detailed declaration, initialization, and
conversion rules appear in their respective chapters.

Templates may generate supported types. An alias gives a type another name
without creating a distinct type.

ImportC may introduce C structs, unions, enums, and incomplete C types.

## Type conversions

A conversion preserves the source value according to the following rules or is
written explicitly with `cast`.

### Implicit conversions

- An integral value may widen to a type which represents its complete value
  range.
- A compile-time integral constant may convert when its value is representable
  in the destination type.
- `float` may convert to `double`.
- A pointer to an object type may convert to a compatibly qualified `void*`.
- `null` may convert to a pointer, slice, function pointer, or delegate.
- Fixed arrays, slices, function pointers, delegates, enums, and qualified
  values use the rules in their dedicated chapters.

Other numeric narrowing and pointer reinterpretation use an explicit cast.

### Pointer conversions

A pointer to an object type implicitly converts to a compatibly qualified
`void*`:

```d
int value;
int* integerPointer = &value;
void* untypedPointer = integerPointer;
```

Converting `void*` to another object pointer type requires an explicit cast:

```d
int* restored = cast(int*) untypedPointer;
```

The conversion does not change the address, adjust alignment, extend the
storage lifetime, or prove that an object of the destination type exists there.

### Integer promotions

Arithmetic promotes `bool`, `byte`, `ubyte`, `short`, `ushort`, `char`, and
`wchar` to `int`. It promotes `dchar` to `uint`. Larger integer types retain
their rank.

### Usual arithmetic conversions

Binary arithmetic first applies integral promotion. If either operand is
`double`, the other numeric operand converts to `double`. Otherwise, if either
operand is `float`, the other numeric operand converts to `float`.

Integral operands convert to a common signed or unsigned type determined by
their rank and representable range.

Enum operations and conversions follow the enums chapter.

## Function types

```text
FunctionType:
    Type function Parameters
    Type delegate Parameters
```

Every Laser-D function type is `nothrow`, `@nogc`, and `@system`, and is
conservatively impure. Its parameters use the passing modes defined by the
functions chapter. Results are values.

Two function types are compatible only when their calling convention,
parameter passing, and result types are compatible.

### Function pointers

A function pointer contains a code address and no context:

```d
int addOne(int value)
{
    return value + 1;
}

int function(int) operation = &addOne;
```

A null function pointer has no callable target.

### Delegates

A delegate contains a function pointer and a context pointer. Laser-D forms
delegate values from non-capturing delegate literals and from struct methods:

```d
struct Offset
{
    int amount;

    int add(int value)
    {
        return amount + value;
    }
}

Offset offset = Offset(4);
int delegate(int) operation = &offset.add;
```

The delegate value has fixed size and does not own or extend the lifetime of
the object addressed by its context.

## Compile-time type inspection

### `typeof`

```text
Typeof:
    typeof ( Expression )
    typeof ( return )
```

`typeof(expression)` produces the compile-time type of an expression without
evaluating the expression:

```d
int inspectWithoutEvaluation()
{
    int value;
    typeof(++value) anotherValue;
    static assert(is(typeof(anotherValue) == int));
    return value;
}

static assert(inspectWithoutEvaluation() == 0);
```

Within a function, `typeof(return)` denotes its result type:

```d
int answer()
{
    typeof(return) value = 42;
    return value;
}
```

Inside a struct or union constructor or instance method, `typeof(this)` denotes
the containing aggregate type.

The `is` expression, templates, and supported `__traits` operations provide
additional compile-time inspection and are described in their own chapters.

## Bottom type

The expression `typeof(*null)` denotes the bottom type: no value of this type is
produced. A program may give it an alias when needed:

```d
alias noreturn = typeof(*null);
```

The bottom type converts to any result type. It can describe a function or
expression which does not return control to its caller.
