---
title: Declarations and types
status: restricted
review-sources: ../spec/declaration.dd, ../spec/type.dd, ../spec/const3.dd, ../spec/enum.dd, ../spec/struct.dd, ../spec/arrays.dd
---

# Declarations and types

This chapter defines Laser-D declarations, types, qualifiers, value
aggregates, arrays, slices, and strings.


## <a id="declarations"></a>Declarations

A declaration introduces a name, storage object, function, aggregate, alias, or
compile-time construct into a scope.

Declarations may occur at module scope, in a struct or union, in a template, or
as declaration statements in a function. The enclosing construct determines
which declaration forms are valid.

```text
Declaration:
    FuncDeclaration
    VarDeclaration
    InferredDeclaration
    AliasDeclaration
    StructDeclaration
    UnionDeclaration
    EnumDeclaration
    ImportDeclaration
    ConditionalDeclaration
    StaticForeachDeclaration
    StaticAssertDeclaration
    TemplateDeclaration
    TemplateMixinDeclaration
    TemplateMixin
```

Structs, unions, and enums are defined later in this chapter. Functions,
imports, conditional compilation, templates, and template mixins are defined
in their respective chapters.

### Variable declarations

```text
VarDeclaration:
    Type DeclaratorInitializers ;

DeclaratorInitializers:
    DeclaratorInitializer
    DeclaratorInitializer , DeclaratorInitializers

DeclaratorInitializer:
    Identifier
    Identifier = Initializer
```

A variable declaration gives one or more names a type and distinct storage:

```d
int count;
int left = 1, right = 2;
int* first, second;
int[4] values;
```

In the final declaration, `values` is fixed-size inline storage. In the pointer
declaration, both `first` and `second` have type `int*`.

A variable without an explicit initializer receives its type's `.init` value:

```d
int count;       // int.init
int* pointer;    // null
int[4] values;   // every element is int.init
```

Every declared variable has a compile-time-known type. The type may contain
qualifiers, pointers, fixed arrays, non-owning slices, function types, or
supported value aggregates as defined by the corresponding sections below.

Struct and union fields use the same basic declaration form. Bit-field
declarators are available only for fields and are defined by the
[structs and unions](#structs-and-unions) section.

### Type inference

```text
InferredDeclaration:
    auto InferredInitializers ;
    immutable InferredInitializers ;
    enum InferredInitializers ;

InferredInitializers:
    InferredInitializer
    InferredInitializer , InferredInitializers

InferredInitializer:
    Identifier = NonVoidInitializer
```

`auto`, `immutable`, and manifest `enum` declarations may infer their type from
an initializer. An inferred declaration always has an initializer, and its type
is fixed at compile time.

```d
auto count = 3;                 // int
immutable limit = 10;           // immutable(int)
enum width = 4;                 // manifest constant of type int
auto text = "Laser-D";          // string
```

Inference does not change the storage or ownership represented by the inferred
type. In particular, inferring a slice produces the same non-owning view as
spelling its type explicitly.

A function result type may also be inferred with `auto`; that form is described
in the functions chapter.

### Initializers

```text
Initializer:
    NonVoidInitializer
    void

NonVoidInitializer:
    AssignExpression
    FixedArrayInitializer
    StructInitializer
```

An expression initializer is evaluated and converted to the declared type.
Fixed-array and struct initializers initialize their corresponding inline value
storage. The detailed rules are defined by the
[arrays and slices](#arrays-and-slices) and
[structs and unions](#structs-and-unions) sections.

```d
int count = 3;
int[4] values = 0;

struct Point
{
    int x;
    int y;
}

Point origin = Point(0, 0);
```

An initializer does not create a separate owning container. A slice initializer,
for example, initializes a pointer-and-length view over storage whose lifetime
is managed elsewhere.

#### Void initialization

A local variable may use `void` initialization to suppress initialization:

```d
int value = void;
```

The program must assign a valid value before reading the variable. `void`
initialization does not alter the variable's type or storage duration.

### Manifest constants

An `enum` declaration without an enum type declares a manifest constant:

```d
enum columns = 4;
enum cells = columns * columns;
```

A manifest constant is evaluated at compile time, occupies no mutable runtime
storage, and may be used wherever a compile-time value is required.

Named enum types and their members are defined in the [enums](#enums) section.

### Static storage

Laser-D module, aggregate, and function-static storage consists of manifest
constants or deeply immutable data whose initializer is fully determined at
compile time:

```d
enum bufferSize = 256;
immutable int tableEntry = 7;

int readTableEntry()
{
    static immutable int localEntry = 11;
    return localEntry;
}
```

These declarations require no startup initialization or shutdown action.

Foreign global storage is declared through an external declaration or ImportC.
Its lifetime and mutation rules belong to the foreign interface.

### Alias declarations

```text
AliasDeclaration:
    alias AliasInitializers ;

AliasInitializers:
    AliasInitializer
    AliasInitializer , AliasInitializers

AliasInitializer:
    Identifier = Type
    Identifier = Symbol
```

An alias introduces another name for a type or symbol. It creates neither
storage nor a distinct type.

```d
alias Index = uint;

int value;
alias current = value;
```

`Index` is another name for `uint`, and `current` denotes the same storage as
`value`.

Aliases may name functions, modules, templates, template instances, manifest
constants, and overload sets:

```d
alias Compare = int function(int left, int right);

template Element(T)
{
    alias Element = T;
}
```

Template alias parameters, alias templates, and eponymous template aliases are
defined in the templates chapter.

### External function declarations

An external function declaration introduces a callable symbol whose definition
is provided by another object file or library:

```d
extern(C) int externalFunction(int value);
```

The declaration emits no Laser-D definition for the symbol. Calls use the
declared type and linkage, which must match the foreign definition.

`extern(C)` is the normal interface to C libraries. ImportC may be used to
translate reviewed C declarations from a preprocessed C source file.



## <a id="types"></a>Types

Laser-D is statically typed. Every expression has a compile-time type. Every
complete object type has a compile-time-known size, alignment, and
representation.

`void` represents the absence of a value. An opaque enum has no complete
representation until its definition is available. ImportC may also introduce
an incomplete C type which can be named and pointed to but not instantiated.

### Type grammar

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

### <a id="basic-data-types"></a>Fundamental types

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

#### `void`

`void` is valid as a function result and as the pointed-to type of `void*`. A
variable, field, or parameter does not have type `void`.

A `void*` can hold the address of any object. Its value carries no type,
alignment, size, ownership, or lifetime guarantee for the referenced storage.

#### `bool`

`bool` has the values `false` and `true`.

Converting zero or a null pointer to `bool` produces `false`. Converting another
scalar value to `bool` produces `true`. Converting a `bool` to an integer
produces zero or one.

#### Null type

The `null` literal has the distinct compile-time type `typeof(null)`. It can
initialize a pointer, slice, function pointer, or delegate:

```d
int* pointer = null;
int[] view = null;
int function(int) operation = null;
int delegate(int) callback = null;
```

### Derived types

Laser-D derives:

- pointers;
- fixed-size arrays;
- non-owning slices;
- function pointers;
- delegates;
- `const` and `immutable` qualified types; and
- compile-time type sequences produced by templates.

The array and qualifier sections below, together with the functions and
templates chapters, define their detailed rules.

#### Component types

A pointer, fixed array, or slice has a component type. A function pointer has a
result type, parameter types, and calling convention. A delegate has the same
callable signature plus a context pointer.

Applying `immutable` to a compound value is transitive through all stored
components. `const` provides a read-only view according to the qualifier rules.

#### Pointers

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

### User-defined value types

Laser-D user-defined runtime types are:

- structs;
- unions; and
- enums.

Structs and unions define fixed-layout value storage. Enums define a named
integral value domain. Their detailed declaration, initialization, and
conversion rules appear in their respective sections below.

Templates may generate supported types. An alias gives a type another name
without creating a distinct type.

ImportC may introduce C structs, unions, enums, and incomplete C types.

### Type conversions

A conversion preserves the source value according to the following rules or is
written explicitly with `cast`.

#### Implicit conversions

- An integral value may widen to a type which represents its complete value
  range.
- A compile-time integral constant may convert when its value is representable
  in the destination type.
- `float` may convert to `double`.
- A pointer to an object type may convert to a compatibly qualified `void*`.
- `null` may convert to a pointer, slice, function pointer, or delegate.
- Fixed arrays, slices, enums, and qualified values use the rules in their
  dedicated sections below. Function pointers and delegates use the functions
  chapter.

Other numeric narrowing and pointer reinterpretation use an explicit cast.

#### Pointer conversions

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

#### Integer promotions

Arithmetic promotes `bool`, `byte`, `ubyte`, `short`, `ushort`, `char`, and
`wchar` to `int`. It promotes `dchar` to `uint`. Larger integer types retain
their rank.

#### Usual arithmetic conversions

Binary arithmetic first applies integral promotion. If either operand is
`double`, the other numeric operand converts to `double`. Otherwise, if either
operand is `float`, the other numeric operand converts to `float`.

Integral operands convert to a common signed or unsigned type determined by
their rank and representable range.

Enum operations and conversions follow the [enums](#enums) section.

### Function types

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

#### Function pointers

A function pointer contains a code address and no context:

```d
int addOne(int value)
{
    return value + 1;
}

int function(int) operation = &addOne;
```

A null function pointer has no callable target.

#### Delegates

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

### Compile-time type inspection

#### `typeof`

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

### Bottom type

The expression `typeof(*null)` denotes the bottom type: no value of this type is
produced. A program may give it an alias when needed:

```d
alias noreturn = typeof(*null);
```

The bottom type converts to any result type. It can describe a function or
expression which does not return control to its caller.



## <a id="type-qualifiers"></a>Type qualifiers

Laser-D has two type qualifiers:

- `const`, an aliasable read-only view; and
- `immutable`, a permanently unmodifiable value and object graph.

Both qualifiers are transitive. Qualifying a pointer, slice, fixed array, or
aggregate qualifies its reachable components and fields.

### Syntax

```text
QualifiedType:
    const Type
    const ( Type )
    immutable Type
    immutable ( Type )
```

The prefix form and type-constructor form denote the same qualified type where
both forms are grammatically valid:

```d
void qualifierForms()
{
    const int first = 1;
    const(int) second = 2;
    immutable int third = 3;
    immutable(int) fourth = 4;

    static assert(is(typeof(first) == const(int)));
    static assert(is(typeof(second) == const(int)));
    static assert(is(typeof(third) == immutable(int)));
    static assert(is(typeof(fourth) == immutable(int)));
}
```

Repeated application of the same qualifier has no additional effect.

### `const`

A `const(T)` expression cannot be used to modify the viewed `T`. The underlying
storage may still be modified through a separate mutable alias:

```d
int observeMutation()
{
    int value = 41;
    const(int)* readOnly = &value;

    value = 42;
    static assert(is(typeof(*readOnly) == const(int)));
    return *readOnly;
}
```

`const` is therefore a statement about access through a particular type, not a
claim that the storage can never change.

This distinction is important for foreign APIs. A `const(char)*`, for example,
allows a function to read character storage without claiming ownership or
permanent immutability.

#### Const parameters and fields

Parameters and fields may use const-qualified types:

```d
import core.stdc.stddef : size_t;

int read(const(int)* value)
{
    return *value;
}

struct View
{
    const(ubyte)* data;
    size_t length;
}
```

The qualifier does not alter pointer size, aggregate layout, calling
convention, ownership, or lifetime.

### `immutable`

An immutable value is initialized once and is not subsequently modified.
Immutability applies transitively to stored components and reachable data.

```d
struct Pair
{
    int first;
    int second;
}

immutable Pair pair = Pair(1, 2);
```

An immutable aggregate's fields are immutable when accessed through that
value. An immutable pointer or slice refers to immutable element storage.

`immutable(T)` denotes the same qualified type everywhere it appears. It does
not depend on the aliases currently in scope.

#### Local initialization

A local immutable value may be initialized by a runtime expression:

```d
int next(int value)
{
    return value + 1;
}

int calculate(int input)
{
    immutable int result = next(input);
    return result;
}
```

The initializer is evaluated before the immutable value becomes available.
Runtime initialization does not make the value a compile-time constant.

The type may be inferred:

```d
immutable result = next(41);
static assert(is(typeof(result) == immutable(int)));
```

#### Static immutable storage

Module, aggregate-static, and function-static immutable values have static
storage when their initializers are fully determined at compile time:

```d
immutable int globalValue = 11;

struct Constants
{
    static immutable int value = 17;
}
```

Such storage requires no startup initialization or shutdown action. A manifest
`enum` is used instead when a name should denote only a compile-time value.

### Derived qualified types

Qualification composes with supported pointers, fixed arrays, slices,
aggregates, aliases, parameters, and template arguments:

```d
alias ReadOnlyInteger = const(int);
alias ImmutableInteger = immutable(int);
alias PointerToConst = const(int)*;
alias ImmutableElements = immutable(int)[];
alias ImmutableArray = immutable(int[4]);
```

The placement of the qualifier determines the derived type. For example,
`const(int)*` is a mutable pointer through which the `int` cannot be modified,
while `const(int*)` is the transitively const-qualified pointer type.

### Qualifier conversions

A mutable value may be viewed through a compatible `const` type:

```d
int readView()
{
    int value = 7;
    const(int)* view = &value;
    return *view;
}
```

An immutable value may also be viewed through a compatible `const` type.
Neither conversion grants ownership or extends the lifetime of referenced
storage.

A scalar or independently stored value aggregate may initialize immutable
destination storage by value:

```d
int copyToImmutable()
{
    int source = 7;
    immutable int scalar = source;

    Pair mutablePair = Pair(1, 2);
    immutable Pair immutablePair = mutablePair;
    return scalar + immutablePair.first;
}
```

For pointers and slices, an immutable conversion is valid only when it
preserves permanent immutability of the referenced storage. A mutable pointer
or slice does not by itself establish that property. String literal storage is
already immutable and may be viewed through an immutable character slice.

An immutable reference does not implicitly convert to a mutable pointer,
slice, or reference.

### Casts

A cast changes the static type used for an expression. It does not change the
physical mutability, ownership, or lifetime of the underlying storage.

Modifying genuinely immutable storage through a cast which removes
`immutable` has undefined behavior. The storage may reside in read-only memory,
and the compiler may optimize under the assumption that it never changes.

Code which needs mutable data creates or receives mutable storage explicitly.

### Immutable receiver methods

A struct or union method may declare an immutable receiver by placing
`immutable` after its parameter list:

```d
struct Value
{
    int number;

    int read() immutable
    {
        return number;
    }
}

int inspect()
{
    immutable Value value = Value(7);
    return value.read();
}
```

Inside the method, `this` is an immutable view of the receiver. The method can
be called on an immutable value and cannot modify its fields.

Overload resolution may distinguish an ordinary mutable-receiver method from an
immutable-receiver method.

### ImportC qualifiers

ImportC preserves C `const` in translated declarations. The resulting types
use the target C ABI and can be passed across the C boundary.



## <a id="enums"></a>Enums

Laser-D enums provide named integral value types, anonymous compile-time
members, manifest constants, and opaque foreign-facing types.

Enum values are fixed-size values. Their declarations and properties are
resolved at compile time.

### Syntax

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

### Named enums

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

#### Default value

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

#### Member values

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

#### Enum-based values

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

### Opaque enums

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

### Anonymous enums

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

### Manifest constants

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

### Properties

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

### Copying, conversion, and operations

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



## <a id="structs-and-unions"></a>Structs and unions

Structs and unions are fixed-layout value types. They provide inline storage,
fields, methods, direct construction, and compile-time layout information.

A struct stores each instance field. A union overlays its instance fields at
the same address.

### Declarations

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

### Fields and storage

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

#### Recursive aggregates

An aggregate can refer to its own type through a pointer:

```d
struct Node
{
    int value;
    Node* next;
}
```

Every field stored directly by value has a complete, finite size.

### Layout

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

### Initialization

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
aggregates use compile-time initializers, as defined by the
[declarations](#declarations) and [type qualifiers](#type-qualifiers) sections.

#### Union initialization

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

### Constructors

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

### Value copying and assignment

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

### Methods and `this`

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

### Named and anonymous unions

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

### Bit fields

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

### Nested and local structs

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

### Aggregate properties

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



## <a id="arrays-and-slices"></a>Arrays and slices

Laser-D has fixed-size arrays and non-owning slices.

| Syntax | Meaning |
| --- | --- |
| `T[n]` | inline storage containing `n` values of type `T` |
| `T[]` | pointer-and-length view of values of type `T` |
| `T*` | pointer with no associated length |

A fixed array contains its elements. A slice refers to storage managed
elsewhere and does not extend that storage's lifetime.

### <a id="static-arrays"></a>Fixed-size arrays

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

The dimension is an integral expression evaluated at compile time:

```d
enum columns = 4;
alias Row = int[columns];
```

The dimension may be zero, including for a struct field. Default and compatible
scalar initialization are accepted; a scalar initializer initializes no
elements:

```d
int[0] empty = 10;
```

The size, alignment, pointer behavior, slicing, and runtime use of zero-length
fixed arrays remain under review.

When the bracket contents are a name, semantic resolution distinguishes a
value used as a fixed-array dimension from a type used as an associative-array
key. Associative arrays remain rejected.

A fixed array stores its elements inline. It may be a local variable, a field,
an element of another fixed array, a function parameter or result, or part of
deeply immutable static storage.

Fixed arrays have value semantics. Assignment, argument passing, and return copy
the element values into the destination array storage.

#### Nested fixed arrays

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

### <a id="dynamic-arrays"></a>Non-owning slices

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

### Initialization

#### Default initialization

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

#### Void initialization

A local fixed array may use `void` initialization:

```d
int[4] values = void;
```

Each element is assigned a valid value before it is read.

#### Fixed-array literals

An array literal initializes fixed destination storage when the complete target
shape is known:

```d
int[3] values = [1, 2, 3];
int[2][2] matrix = [[1, 2], [3, 4]];
```

Each initializer is converted to the corresponding element type and written
directly into the fixed array.

#### Scalar initialization and filling

A compatible scalar initializer or full-slice assignment fills existing
elements:

```d
void clear(int[] values)
{
    values[] = 0;
}
```

No new backing storage is created.

For a zero-length fixed array, scalar initialization is valid and performs no
element assignments.

#### Static initialization

A fixed array in deeply immutable static storage has a compile-time initializer:

```d
immutable int[4] table = [1, 2, 3, 4];
```

String literals provide their own compiler-managed immutable static storage, as
described below.

### Indexing

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

### Slicing

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

### Properties

#### `.length`

`.length` is the number of elements.

For a fixed array, it is a compile-time property determined by the type. For a
slice, it is the number of elements in the current view.

The property is read-only.

#### `.ptr`

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

### Assignment to existing storage

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

### Strings

A string literal is immutable compiler-managed static character storage.

| Literal | Element type |
| --- | --- |
| `"Laser-D"` | `immutable(char)` |
| `"Laser-D"w` | `immutable(wchar)` |
| `"Laser-D"d` | `immutable(dchar)` |

The literal is normally used through an immutable character slice:

```d
string text = "Laser-D";
```

Laser-D's implicitly imported minimal `object` module defines the conventional
character-slice aliases:

```d
alias string  = immutable(char)[];
alias wstring = immutable(wchar)[];
alias dstring = immutable(dchar)[];
```

These are ordinary aliases and do not imply allocation, ownership, garbage
collection, or other runtime support.

String slices may be indexed, sliced, passed, and returned:

```d
string trim(string value)
{
    return value[1 .. $ - 1];
}
```

Indexing operates on UTF-8, UTF-16, or UTF-32 code units according to the
element type. It does not implicitly decode, normalize, or transcode text.

Literal storage cannot be modified and does not implicitly convert to a mutable
character slice.

#### String comparison

`==` and `!=` compare compatible character slices element by element:

```d
bool equal(string left, string right)
{
    return left == right;
}
```

`is` and `!is` compare the identity of the slice view:

```d
bool sameView(string left, string right)
{
    return left is right;
}
```

Identity compares the represented view rather than the character contents.

#### Character pointers and C strings

A character pointer has no length and does not by itself establish
zero-termination:

```d
extern(C) int consume(const(char)* text);
```

C-string termination, encoding, ownership, and lifetime follow the foreign
API's contract.

### Conversions

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
