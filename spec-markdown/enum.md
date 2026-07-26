# Enums

Laser-D enums provide named integral value types, anonymous compile-time
members, manifest constants, and opaque foreign-facing types.

Enum values are fixed-size values. Their declarations and properties are
resolved at compile time.

## Syntax

```text
EnumDeclaration:
    enum Identifier EnumBody
    enum Identifier : EnumBaseType EnumBody
    enum Identifier : EnumBaseType ;
    AnonymousEnumDeclaration
    ManifestConstantDeclaration

EnumBaseType:
    Type

EnumBody:
    { EnumMembers }

EnumMembers:
    EnumMember
    EnumMember ,
    EnumMember , EnumMembers

EnumMember:
    Identifier
    Identifier = AssignExpression

AnonymousEnumDeclaration:
    enum { AnonymousEnumMembers }
    enum : EnumBaseType { EnumMembers }

AnonymousEnumMembers:
    AnonymousEnumMember
    AnonymousEnumMember ,
    AnonymousEnumMember , AnonymousEnumMembers

AnonymousEnumMember:
    Identifier
    Identifier = AssignExpression
    Type Identifier = AssignExpression

ManifestConstantDeclaration:
    enum Identifier = AssignExpression ;
    enum Type Identifier = AssignExpression ;
```

## Named enums

A named enum introduces a distinct value type. Its members belong to the enum's
scope and have the named enum type:

```d
enum Direction : ubyte
{
    north,
    east,
    south,
    west,
}
```

The base is a supported integral type or another named enum. When the base is
omitted, it is `int`.

Members are referenced through the enum name:

```d
Direction direction = Direction.north;
```

An enum member's type is the named enum type. Constructing the same named enum
type from one of its values preserves that type:

```d
static assert(is(typeof(Direction.north) == Direction));
static assert(is(typeof(Direction(Direction.north)) == Direction));
```

An enum value converts to its base type where the ordinary value-conversion
rules permit. Converting a base value to the named enum uses an explicit cast:

```d
ubyte encoded = Direction.east;
Direction decoded = cast(Direction) encoded;
```

### Default value

A defined named enum's `.init` value is its first declared member, regardless
of that member's numeric value:

```d
enum Status : int
{
    ready = 4,
    running = 7,
}

Status status;
static assert(Status.init == Status.ready);
```

### Member values

A member initializer is a compile-time expression converted to the enum base
type.

For an enum with an integral base, the first member without an initializer uses
the base type's zero value. Each subsequent uninitialized member is the
previous member plus one:

```d
enum Code : ushort
{
    first,
    second,
    explicitValue = 10,
    following,
}

static assert(Code.first == 0);
static assert(Code.second == 1);
static assert(Code.following == 11);
```

Automatic assignment must produce a representable, distinct value. An explicit
initializer is used at an overflow boundary or whenever the desired value is
not the preceding value plus one.

Member initializers use ordinary compile-time name lookup. Forward references
and circular value dependencies must be resolvable at compile time.

### Enum-based values

When the base type is another enum, the first member may use the base enum's
default value or an explicit base-enum value. Every following member has an
explicit initializer:

```d
enum Base : int
{
    zero,
    one,
}

enum Derived : Base
{
    first = Base.zero,
    second = Base.one,
}
```

This preserves the value domain of the base enum without applying implicit
arithmetic to it.

## Opaque enums

A named enum declaration with a base type and no body introduces an opaque
enum:

```d
enum NativeHandle : uint;
```

The base supplies the opaque enum's size and alignment. Its members and default
value are unknown, so every object of the type is initialized with an explicit
value:

```d
NativeHandle handle = cast(NativeHandle) 1u;
```

Opaque enums may be used in function signatures, pointers, aggregates, and
foreign interfaces.

## Anonymous enums

An enum declaration without a name introduces its members directly into the
surrounding scope and does not create a named enum type:

```d
enum
{
    bufferSize = 256,
    retryCount = 3,
}
```

With an explicit base, each member has that base type:

```d
enum : ushort
{
    readFlag = 1,
    writeFlag = 2,
}
```

Without an explicit base, a member's type comes from its written type,
initializer, previous member, or `int`, as applicable. Uninitialized members
use the same checked increment rule as an integral-based named enum.

## Manifest constants

The single-member form declares a manifest constant:

```d
enum pageSize = 4096;
enum ulong elementSize = int.sizeof;
```

A manifest constant:

- is evaluated at compile time;
- has no runtime storage;
- is not an lvalue; and
- can be used wherever its value is valid at compile time.

```d
enum rows = 3;
enum columns = 4;
alias Matrix = int[columns][rows];

static assert(Matrix.sizeof == rows * columns * int.sizeof);
```

Manifest constants may be declared at module, aggregate, function, or template
scope.

## Properties

Defined named enums provide:

| Property | Meaning |
| --- | --- |
| `.init` | first declared member |
| `.min` | member with the smallest declared value |
| `.max` | member with the largest declared value |
| `.sizeof` | storage size of the enum type |
| `.alignof` | alignment of the enum type |

`.min` and `.max` are compile-time values. An opaque enum provides layout
properties derived from its base but has no member-dependent properties.

The common compiler properties, including `.stringof` and `.mangleof`, are
defined in the properties chapter.

## Copying, conversion, and operations

Enum values use ordinary value copying and assignment:

```d
Direction first = Direction.north;
Direction second = first;
```

Comparisons, casts, integral operations, and bitwise operations follow the
expression and conversion rules for the enum's base while preserving the
requirements of the destination type.

Equality and inequality also accept a `const` view of the same enum value.

An ordinary `switch` may select enum values. A `final switch` over a defined
named enum must cover its declared members, as specified by the statements
chapter.
