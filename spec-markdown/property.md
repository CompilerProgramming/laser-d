---
title: Properties
status: restricted
review-sources: ../spec/property.dd
---

# Compiler-provided properties

Compiler-provided properties expose compile-time metadata or an
allocation-free view of a supported value. Property access does not invoke
source-defined behavior.

Differences from D properties are summarized in
[D compatibility notes](d-compatibility.md).

## Property summary

| Property | Applies to | Result |
| --- | --- | --- |
| `.init` | supported types and expressions | default initializer |
| `.sizeof` | supported types, expressions, and fields | size in bytes |
| `.alignof` | supported types and expressions | required alignment in bytes |
| `.stringof` | supported syntax and symbols | compile-time source representation |
| `.mangleof` | supported types and symbols | compile-time mangled representation |
| `.tupleof` | structs, unions, and their values | field symbol sequence |
| `.offsetof` | struct and union fields | byte offset within the aggregate |
| `.length` | fixed arrays and slices | element count |
| `.ptr` | fixed arrays, slices, and delegates | data or context pointer |
| `.funcptr` | delegates | function pointer |
| `.min`, `.max` | integral, floating-point, and enum types | numeric or enum limits |

Layout and mangling results follow the target ABI and can differ between
supported targets.

## Default initialization

`T.init` is the compile-time default initializer for `T`. Applying `.init` to
an expression, variable, or field yields the initializer for its type without
evaluating the expression.

| Type category | Default |
| --- | --- |
| `bool` | `false` |
| integer types | zero |
| `float` and `double` | not-a-number |
| character types | the specified invalid code-unit sentinel |
| pointers | `null` |
| slices | `null` |
| function pointers | `null` |
| delegates | `null` |
| fixed arrays | each element's default |
| structs | each field's declared or type default |
| unions | the default selected by the union initialization rules |
| enums | the initializer defined by the enum |

`.init` produces the structural default value and does not invoke a struct
constructor.

```d
struct Point
{
    int x;
    int y = 2;
}

static assert(Point.init.x == 0);
static assert(Point.init.y == 2);
```

## Source representation

`prefix.stringof` is a compile-time string containing the frontend's source
representation of its prefix. The prefix is not evaluated. Formatting is
implementation-defined and is intended for inspection and diagnostics.

```d
static assert(int.stringof == "int");
static assert((1 + 2).stringof == "1 + 2");
```

## Size and alignment

`T.sizeof` is the number of bytes occupied by a value of type `T`. For an
expression or field, it is the size of that expression's type. Reading the
property does not evaluate an expression or require an aggregate instance.

`T.alignof` is the byte alignment required by `T` under the target ABI. It
reports layout and does not request or change alignment.

```d
struct Pair
{
    int first;
    int second;
}

static assert(int.sizeof == 4);
static assert(Pair.first.sizeof == int.sizeof);
```

## Field offsets and sequences

`Aggregate.field.offsetof` is the byte offset of a non-static struct or union
field from the beginning of its containing value.

`Aggregate.tupleof` and `value.tupleof` are compile-time symbol sequences
containing the non-static fields of a struct or union in declaration order.
The value form provides the fields of that value and can be used by
compile-time-expanded iteration.

```d
struct Vector2
{
    int x;
    int y;
}

static assert(Vector2.x.offsetof == 0);
static assert(Vector2.tupleof.length == 2);
```

## Mangled representation

`symbol.mangleof` or `T.mangleof` is a compile-time string containing the
object-file name or type encoding selected by the applicable linkage and ABI.

```d
static assert(int.mangleof == "i");
```

## Numeric properties

Integral types provide `.min` and `.max`.

`float` and `double` provide:

| Property | Meaning |
| --- | --- |
| `.infinity` | positive infinity |
| `.nan` | quiet not-a-number value |
| `.dig` | decimal precision |
| `.epsilon` | increment from one |
| `.mant_dig` | significand precision in bits |
| `.max_10_exp` | maximum base-10 exponent |
| `.max_exp` | maximum base-2 exponent |
| `.min_10_exp` | minimum normalized base-10 exponent |
| `.min_exp` | minimum normalized base-2 exponent |
| `.max` | largest finite value |
| `.min_normal` | smallest positive normalized value |
| `.re` | the value itself |

These values describe the target representation selected for the type.

## Arrays and slices

Fixed arrays and slices provide read-only `.length` and `.ptr`.

- For a fixed array, `.length` is the element count encoded in its type and
  `.ptr` points to its first element.
- For a slice, `.length` and `.ptr` expose the two components of the non-owning
  view.

The pointer does not own or extend the lifetime of the backing storage. See
[Arrays](types.md#arrays-and-slices) for the slice lifetime and mutation rules.

## Delegates

A delegate provides `.ptr`, its context pointer, and `.funcptr`, its function
pointer. These properties expose the delegate representation and do not
allocate. A non-capturing delegate has a null context pointer.

## Enums

An enum provides `.init`, `.min`, `.max`, `.sizeof`, and `.alignof` according
to its declaration and base type. See [Enums](types.md#enums).
