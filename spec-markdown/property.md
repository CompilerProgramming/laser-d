---
title: Properties
status: restricted
source: ../spec/property.dd
---

# Compiler-Provided Properties

> **Laser-D normative:**
>
> Compiler-provided properties are supported when they expose
> compile-time metadata or an allocation-free view of a supported value. A
> property cannot introduce a rejected type, allocate storage, resize a value, or
> invoke user-defined behavior.

> **Excluded from Laser-D:**
>
> User-defined `@property` functions are not part of Laser-D.
> All ordinary functions, methods, UFCS calls, and templates require explicit
> call parentheses. Source-defined behavior therefore cannot masquerade as field
> access.

## <a id="common"></a>Common Properties

| Property | Result |
| --- | --- |
| [`.stringof`](#stringof) | compile-time source representation |
| [`.mangleof`](#mangleof) | compile-time mangled representation |

## <a id="type"></a>Type and Layout Properties

| Property | Result |
| --- | --- |
| [`.init`](#init) | default initializer |
| [`.sizeof`](#sizeof) | size in bytes |
| [`.alignof`](#alignof) | required alignment in bytes |
| [`.tupleof`](#tupleof) | aggregate field symbol sequence |
| [`.offsetof`](#offsetof) | byte offset of an aggregate field |

These properties are compile-time values. Layout results are target ABI
properties and may differ between supported targets.

## <a id="numeric"></a>Numeric Properties

Supported integral types provide `.min` and `.max`. Supported
floating-point types `float` and `double` provide:

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

> **Excluded from Laser-D:**
>
> Numeric properties on `real`, imaginary, complex, 128-bit
> integer, or vector types are unavailable because those types are rejected.

> **Excluded from Laser-D:**
>
> The legacy floating-point `.im` property is not part of
> Laser-D. It belongs to D's imaginary and complex number model, whose types are
> rejected. An aggregate may still declare an ordinary field named `im`.

## <a id="init"></a>`.init` Property

`T.init` is the compile-time default initializer for `T`. Applying
`.init` to a variable, field, or expression yields the default initializer
of its type; it does not read or evaluate the value.

| Type category | Default |  |  |  |
| --- | --- | --- | --- | --- |
| `bool` | `false` |  |  |  |
| integer types | zero |  |  |  |
| `float` and `double` | not-a-number |  |  |  |
| character types | their specified invalid code-unit sentinel |  |  |  |
| pointers | slices | function pointers | and delegates | `null` |
| fixed arrays | each element's default |  |  |  |
| structs | each field's declared or type default |  |  |  |
| unions | the selected default field described by the union rules |  |  |  |
| enums | the enum initializer described by the enum rules |  |  |  |

### <a id="init-vs-construction"></a>`.init` and Construction

`.init` does not call a constructor. It produces the structural default
value. A struct constructor is an explicitly invoked function-like operation
and may produce a different value.

```d
struct Point
{
    int x;
    int y = 2;
}

static assert(Point.init.x == 0);
static assert(Point.init.y == 2);
```

## <a id="stringof"></a>`.stringof` Property

`value.stringof` is a compile-time string containing the frontend's
source representation of its prefix. The prefix is not evaluated. Formatting
is implementation-defined and must not be used to generate source code.

```d
static assert(int.stringof == "int");
static assert((1 + 2).stringof == "1 + 2");
```

## <a id="sizeof"></a>`.sizeof` Property

`T.sizeof` is the number of bytes occupied by a value of type `T`.
For an expression or field it is the size of that expression's type. It does
not evaluate an expression or require an aggregate instance.

```d
struct Pair { int first; int second; }
static assert(int.sizeof == 4);
static assert(Pair.first.sizeof == int.sizeof);
```

## <a id="alignof"></a>`.alignof` Property

`T.alignof` is the byte alignment required by type `T` on the target
ABI. It describes type layout and does not request or change alignment.

## <a id="offsetof"></a>`.offsetof` Property

`Aggregate.field.offsetof` is the byte offset of a non-static struct or
union field from the beginning of its containing value. It is a compile-time
ABI value.

## <a id="mangleof"></a>`.mangleof` Property

`symbol.mangleof` or `T.mangleof` is a compile-time string containing
the object-file name or type encoding selected by the applicable linkage and
ABI. Non-D linkage follows the target interoperability rules.

## <a id="tupleof"></a>`.tupleof` Property

`Aggregate.tupleof` or `value.tupleof` is a compile-time symbol
sequence containing the non-static fields of a supported struct or union in
declaration order. Iterating it does not allocate runtime storage.

```d
struct Vector2 { int x; int y; }
static assert(Vector2.tupleof.length == 2);
```

## <a id="arrays"></a>Array and Slice Properties

Fixed arrays and non-owning slices provide read-only `.length` and
`.ptr`. Fixed-array length is part of the type. Slice length and pointer are
the two components of the view. Assigning to slice `.length` is rejected.

> **Excluded from Laser-D:** `.dup`, `.idup`, `.capacity`, reservation, resizing, and other GC-backed array properties are unavailable.

## <a id="delegates"></a>Delegate Properties

A supported delegate provides `.ptr`, its context pointer, and
`.funcptr`, its function pointer. These properties expose the fixed-size
delegate representation and do not allocate. A non-capturing delegate has a
null context pointer.

## <a id="enums"></a>Enum Properties

Supported enums provide `.init`, `.min`, `.max`, and layout
properties as defined by the enum chapter. Opaque enums have no usable default
initializer until defined.

## <a id="classinfo"></a>Excluded Runtime Properties

> **Excluded from Laser-D:**
>
> `.classinfo`, runtime `TypeInfo`, class layout
> properties, associative-array properties, and vector properties are not part
> of Laser-D. Their underlying type or runtime facility is absent.

## <a id="classproperties"></a>User-Defined Properties (Excluded)

> **Excluded from Laser-D:**
>
> The `@property` attribute is rejected on free functions, methods, templates, getters, setters, immutable receivers, and UFCS functions.
> Calling a function without parentheses is also rejected independently.
