---
title: Enums
status: supported
source: ../spec/enum.dd
---

# Enums

Laser-D supports named, anonymous, based, and opaque enums together with
single-member manifest constants. Enum declarations create compile-time values
and, for named enums, lightweight value types. They require no D runtime or
TypeInfo.

```text
EnumDeclaration:
    enum Identifier EnumBody
    enum Identifier : EnumBaseType EnumBody
    AnonymousEnumDeclaration

EnumBaseType:
    Type

EnumBody:
    { EnumMembers }
    ;

EnumMembers:
    EnumMember
    EnumMember ,
    EnumMember , EnumMembers

EnumMember:
    Identifier
    Identifier = AssignExpression

AnonymousEnumDeclaration:
    enum : EnumBaseType { EnumMembers }
    enum { AnonymousEnumMembers }

AnonymousEnumMembers:
    AnonymousEnumMember
    AnonymousEnumMember ,
    AnonymousEnumMember , AnonymousEnumMembers

AnonymousEnumMember:
    EnumMember
    Type Identifier = AssignExpression
```

> **Rejected in Laser-D:**
>
> Enum members cannot carry user-defined attributes or
> `@disable`. Other built-in declaration attributes are available only when
> their individual Laser-D specifications permit them.

## <a id="named_enums"></a>Named Enums

A named enum introduces a distinct value type. Its members are declared in
the enum's scope and have the named enum type.

```d
enum Direction : ubyte
{
    north
east
south
west
}
```

A named enum base may be a retained primitive scalar type or another named
enum. If no base is written, the base is inferred from the first explicit
member value when possible and otherwise defaults to `int`. A rejected type
cannot be introduced as an enum base.

An enum value implicitly converts to its base type where the ordinary
conversion rules allow. A base-type value does not implicitly convert to the
named enum; an explicit cast or an enum member is required.

<a id="enum_default_initializer"></a>enum_variables

A defined named enum default-initializes to the value of its first member, not necessarily to numeric zero.

```d
d
enum Status : int
{
    ready = 4
running = 7
}

Status value;
static assert(Status.init == Status.ready);

```

### <a id="member_values"></a>Enum Member Values

A member with an initializer uses its compile-time value after conversion
to the enum base. The initializer is subject to all ordinary Laser-D and CTFE
restrictions.

For an enum whose base is not another enum, the first uninitialized member
has the base type's zero/default value. Each later uninitialized member is the
previous member plus one. The compiler rejects overflow, a base without a
compile-time `+ 1` operation, or an increment that does not change the
value.

```d
d
enum Code : ushort
{
    first
second
explicitValue = 10
following
}

static assert(Code.first == 0);
static assert(Code.second == 1);
static assert(Code.following == 11);

```

All members are visible to member initializer expressions, subject to
normal forward-reference and circular-dependency diagnostics.

#### <a id="enum-based-values"></a>Enum-Based Values

> **Laser-D normative:**
>
> When the base type is another enum, the first member may use
> the base enum's default value or an explicit value. Every member after the
> first must have an explicit initializer. Laser-D does not implicitly apply
> arithmetic to produce the next value of another enum type.

```d
enum Base : int { zero
one }

enum Derived : Base
{
    first = Base.zero
second = Base.one
}
```

#### <a id="opaque-enums"></a>Opaque Enums

A named declaration with a base type and no body introduces an opaque enum.

```d
enum NativeHandle : uint;
```

> **Laser-D normative:**
>
> An opaque enum has a known size and alignment but no known
> members and no default initializer. It may be used in declarations that supply
> an explicit value, in function signatures, and for interoperability. A
> default-initialized variable of opaque enum type is rejected.

### <a id="enum_properties"></a>Enum Properties

| Property | Meaning |
| --- | --- |
| `.init` | Value of the first declared member |
| `.min` | Smallest declared member value |
| `.max` | Largest declared member value |
| `.sizeof` | Storage size of an enum value |

Computing `.min` and `.max` requires member values that the compiler
can compare at compile time. Opaque enums have `.sizeof` through their base
type but no member-dependent `.init`, `.min`, or `.max`. Generic
compiler properties such as `.stringof` remain governed by the properties
chapter.

### <a id="enum_copying_and_assignment"></a>Copying and Assignment

Enum values have ordinary value-copy and assignment semantics. They never
invoke a struct copy constructor, move constructor, postblit, destructor, or
assignment hook. Those aggregate lifecycle facilities are independently
rejected or restricted by the struct and operator chapters.

## <a id="anonymous_enums"></a>Anonymous Enums

An enum declaration without a name introduces its members directly into the
surrounding scope and does not create a new enum type.

```d
enum
{
    bufferSize = 256
retryCount = 3
}
```

With an explicit base, every member has that base type. Without a base, a
member's type is its explicitly written type, the type of its initializer, the
previous member's type, or `int`, in that order where applicable. Every such
type must itself be supported by Laser-D.

Uninitialized anonymous members use the same initial-value and checked
increment rules as named enums whose base is not another enum.

### <a id="single_member"></a>Single-Member Syntax

A single anonymous member may omit braces. This form declares a manifest
constant.

```d
enum pageSize = 4096;
enum ulong elementSize = int.sizeof;
```

## <a id="manifest_constants"></a>Manifest Constants

A manifest constant exists only at compile time. It has no runtime storage, is not an lvalue, and its address cannot be taken. Its initializer is evaluated
by CTFE and must use only supported Laser-D constructs.

```d
d
enum rows = 3;
enum columns = 4;
alias Matrix = int[columns][rows];

static assert(Matrix.sizeof == rows * columns * int.sizeof);

```

Manifest constants may be declared at module, aggregate, function, template, or other scopes where an ordinary declaration is permitted. They do not violate
the rejection of mutable static storage because they have no runtime location.

## <a id="conversions"></a>Enum Conversions and Operations

Enum casts, comparisons, arithmetic, bitwise operations, and switch behavior
follow the type, expression, and statement chapters. Operations cannot produce
a rejected type or invoke unavailable runtime support. A `final switch` over
a defined named enum provides compile-time exhaustiveness checking over its
declared members.

## <a id="conformance"></a>Conformance Boundary

Laser-D enum conformance includes named and anonymous enums, retained scalar
and enum bases, explicit and checked implicit member values, ordinary enum
properties, opaque enum types, manifest constants, value copying, and switch
use. Attribute-bearing members, rejected base types, default initialization of
opaque enums, and implicit continuation of enum-based member values are outside
the language.
