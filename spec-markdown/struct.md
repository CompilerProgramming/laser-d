---
title: Structs and unions
status: restricted
source: ../spec/struct.dd
---

# Structs and unions

Structs and unions are fixed-layout value types. They provide inline storage,
fields, methods, direct construction, and compile-time layout information.

A struct stores each instance field. A union overlays its instance fields at
the same address.

## Declarations

```text
StructDeclaration:
    struct Identifier { AggregateMembers }

UnionDeclaration:
    union Identifier { AggregateMembers }

AggregateMembers:
    AggregateMember*

AggregateMember:
    FieldDeclaration
    MethodDeclaration
    Constructor
    StructDeclaration
    UnionDeclaration
    EnumDeclaration
    TemplateDeclaration
    TemplateMixin
    StaticAssertDeclaration
    ManifestConstantDeclaration
```

A struct declaration introduces a value type:

```d
struct Point
{
    int x;
    int y;

    int sum()
    {
        return x + y;
    }
}
```

A union declaration introduces overlapping value storage:

```d
union Word
{
    uint whole;
    ushort half;
}
```

The language does not record which union field was most recently written. The
program maintains any active-field convention required by its data model.

ImportC structs and unions use the C declarations and layout rules defined by
the ImportC chapter.

## Fields and storage

Each non-static struct field occupies distinct storage in its containing
object. Every union field begins at the union's address.

An aggregate value contains its instance fields and ABI padding. Methods,
templates, manifest constants, and other compile-time members add no per-value
storage or hidden dispatch table.

Aggregate values may be:

- local variables;
- fields of another value aggregate;
- elements of fixed-size arrays;
- function parameters or results;
- deeply immutable static values; or
- values addressed through explicitly managed foreign storage.

The lifetime of an aggregate is the lifetime of its containing storage.

### Recursive aggregates

An aggregate can refer to its own type through a pointer:

```d
struct Node
{
    int value;
    Node* next;
}
```

Every field stored directly by value has a complete, finite size.

## Layout

Struct fields are laid out in declaration order, with padding inserted
according to the target ABI. A union's size and alignment accommodate every
field.

The following compile-time properties expose layout:

- type `.sizeof`;
- type `.alignof`;
- field `.offsetof`; and
- aggregate `.tupleof`.

```d
struct Pair
{
    int first;
    int second;
}

static assert(Pair.first.offsetof == 0);
static assert(Pair.second.offsetof >= int.sizeof);
static assert(Pair.sizeof >= 2 * int.sizeof);
```

Padding, alignment, byte order, and bit-field packing follow the target ABI.
Foreign interfaces verify the layout required on each supported target rather
than assuming binary identity between targets.

## Initialization

Default initialization initializes each struct field from its field initializer
or the field type's `.init` value:

```d
struct Position
{
    int x = 1;
    int y;
}

Position position;
static assert(Position.init.x == 1);
static assert(Position.init.y == 0);
```

A struct literal names the type and supplies field values in declaration order:

```d
Point origin = Point(0, 0);
```

Omitted trailing fields use their declared default initialization.

Local aggregates may be initialized at runtime. Deeply immutable static
aggregates use compile-time initializers, as defined by the declarations and
qualifiers chapters.

### Union initialization

At most one overlapping union field has a default initializer. A union without
one uses its ordinary default representation.

```d
union Number
{
    uint unsignedValue = 0;
    int signedValue;
}
```

A union constructor may explicitly select and initialize a representation.
Changing fields later writes the same overlapping storage.

## Constructors

A constructor is named `this` and initializes an aggregate in existing
destination storage:

```d
struct ResourceId
{
    uint value;

    this(uint initialValue)
    {
        value = initialValue;
    }
}

ResourceId id = ResourceId(42);
```

A constructor has no source-level result value. It initializes fields directly
and follows the ordinary Laser-D parameter, calling-convention, template, and
function-body rules.

Templated constructors are available:

```d
struct Cell
{
    int value;

    this(T)(T initialValue)
    {
        value = cast(int) initialValue;
    }
}
```

Union constructors use the same syntax:

```d
union Word
{
    uint whole;
    ushort half;

    this(uint value)
    {
        whole = value;
    }
}
```

Construction initializes storage already provided by a declaration, enclosing
aggregate, caller, or foreign allocation API.

## Value copying and assignment

An aggregate whose fields are value-copyable has ordinary field-wise value
semantics:

```d
Point first = Point(2, 3);
Point second = first;
second = Point(4, 5);
```

Copying a pointer or slice field copies its non-owning address or view; it does
not copy the referenced storage or extend its lifetime.

Modern assignment and compound-assignment hooks may customize assignment as
defined by the operator-overloading chapter.

The supported `__traits` predicates can inspect properties such as POD,
copyability, zero initialization, construction, and destruction.

## Methods and `this`

Struct and union methods are ordinary functions associated with an aggregate
type. They are called with explicit parentheses:

```d
struct Counter
{
    int value;

    void increment()
    {
        ++value;
    }

    int read()
    {
        return value;
    }
}
```

Inside an instance method or constructor, `this` denotes the current aggregate.
It may:

- qualify a field or method;
- be passed or returned by value;
- have its address taken as a non-owning pointer;
- form a delegate to one of its methods; and
- participate in `typeof` and template inference.

An immutable receiver method places `immutable` after its parameter list and
may be called on an immutable aggregate:

```d
struct Value
{
    int number;

    int read() immutable
    {
        return number;
    }
}
```

## Named and anonymous unions

A named union declares a reusable type. An anonymous union directly overlays
fields in its containing aggregate:

```d
struct TaggedValue
{
    int tag;

    union
    {
        int integer;
        float floating;
    }
}
```

The anonymous union contributes `integer` and `floating` as fields of
`TaggedValue`. They share storage and follow the same initialization and layout
rules as fields of a named union.

## Bit fields

Integral bit fields pack values into implementation-defined allocation units:

```text
BitFieldDeclaration:
    IntegralType Identifier : Width ;
    IntegralType Identifier : Width = Initializer ;
    IntegralType : 0 ;
```

```d
struct Flags
{
    uint low : 3 = 1;
    uint high : 5 = 2;
    uint : 0;
    int signedValue : 4;
}
```

A named bit field:

- has an integral storage type;
- has a positive compile-time width no greater than that type's bit width;
- may have a representable default initializer; and
- supports ordinary access and assignment.

An anonymous zero-width field ends the current allocation unit. Bit-field
packing order and allocation-unit layout are implementation-defined.

Bit fields are also available in unions:

```d
union Overlay
{
    uint whole;
    uint low : 4;
}
```

The field properties `.min` and `.max` reflect the bit width and signedness.
The supported bit-field traits expose whether a field is a bit field and its
declared width.

## Nested and local structs

A struct may be declared in a module, aggregate, template, or function.

A function-local struct is a context-free value type. Its methods use its own
fields, parameters, manifest constants, and names available without an outer
runtime object:

```d
int calculate()
{
    struct LocalValue
    {
        int value;

        int doubled()
        {
            return value * 2;
        }
    }

    LocalValue local = LocalValue(21);
    return local.doubled();
}
```

Values needed by the local type are represented explicitly as fields or passed
as function parameters.

## Aggregate properties

Struct and union types and values provide the compiler properties defined in
the properties chapter. The principal aggregate properties are:

- `.init`;
- `.sizeof`;
- `.alignof`;
- `.tupleof`;
- `.stringof`; and
- field `.offsetof`.

These properties are compile-time information and do not add storage to an
aggregate.
