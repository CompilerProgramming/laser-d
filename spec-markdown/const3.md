---
title: Type qualifiers
status: restricted
source: ../spec/const3.dd
---

# Type Qualifiers

Laser-D supports the `const` and `immutable` source-level type
qualifiers. `const` provides an aliasable read-only view. `immutable`
retains D's transitive immutable semantics: after initialization, an immutable
value and every value reachable through it cannot be modified.

> **Rejected in Laser-D:**
>
> The D qualifiers `inout` and `shared` are not supported
> in Laser-D source. Postfix `const` function and receiver qualifiers are also
> rejected; `const` is retained solely as a type qualifier.

## <a id="Type"></a>Qualifier Grammar

```text
QualifiedType:
    const ( Type )
    const Type
    immutable ( Type )
    immutable Type
```

The prefix storage-class form and the type-constructor form describe the
same qualified type where both grammars are valid.

```d
const int readOnly = 1;
const(int) alsoReadOnly = 2;
immutable int first = 1;
immutable(int) second = 2;
```

## <a id="const_and_immutable"></a>and Immutable Values

An unqualified Laser-D value is mutable unless another rule makes the
particular view unmodifiable. A `const` view cannot be used to modify its
referent, although another mutable alias may modify the same data. An
`immutable` value is initialized once and cannot subsequently be assigned
or mutated through any alias.

Immutability is transitive. Applying `immutable` to a pointer, slice, fixed array, or aggregate applies to its reachable components and fields, not
only to the outer reference value.

```d
struct Pair
{
    int first;
    int second;
}

immutable Pair pair = Pair(1, 2);
// pair.first = 3; // rejected
```

`immutable` means permanently unmodifiable, whereas `const` means
read-only through the qualified view. This distinction permits accurate C
library declarations without claiming that foreign data is permanently
immutable.

## <a id="immutable_storage_class"></a>Immutable Declarations

An immutable declaration requires a valid initializer unless the type has a
usable default value and the declaration context permits default
initialization. Type inference from the initializer is supported.

```d
d
immutable int explicitType = 3;
immutable inferredType = 4;

static assert(is(typeof(inferredType) == immutable(int)));

```

A local immutable value may be initialized by a runtime expression. The
initializer is evaluated before the value becomes available for ordinary use.

```d
d
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

Runtime initialization does not make a value a compile-time constant. Use a
manifest `enum` when the declaration must exist only at compile time.

### <a id="immutable-static-storage"></a>Immutable Static Storage

Deeply immutable module, aggregate-static, and function-static values are
permitted when their initializers satisfy Laser-D's static-initialization
rules. They require no mutable static storage or module lifecycle function.

> **Rejected in Laser-D:**
>
> An immutable static declaration cannot defer initialization to
> a module constructor. Module constructors, including shared module
> constructors, are rejected.

## <a id="const_storage_class"></a>Const Type Qualifier

Both `const Type` and `const(Type)` form a read-only view of a
supported type. Qualification is transitive through pointers, slices, fixed
arrays, and aggregate fields as defined by D's type system. Mutable and
immutable values may be viewed as `const` when the ordinary qualifier
conversion rules permit it.

> **Rejected in Laser-D:**
>
> Writing `const` after a function parameter list would
> qualify a member-function receiver rather than a data type. That postfix form
> is rejected; use an `immutable` receiver only when the complete value is
> permanently immutable.

## <a id="immutable_type"></a>Immutable Types

`immutable(Type)` forms the transitively immutable form of a supported
type. Applying it repeatedly has no additional effect.

```d
alias ImmutableInt = immutable(int);
alias ImmutablePair = immutable(Pair);
```

A rejected type does not become available merely by qualifying it. For
example, immutable classes, associative arrays, and rejected scalar types
remain unavailable.

## <a id="creating_immutable_data"></a>Creating Immutable Data

Immutable scalar and value-type data is created by initializing its final
storage from a compatible expression. Ordinary value-copyable structs may be
copied into immutable destination storage without invoking a copy or move
constructor, because those constructors are rejected.

For pointers and slices, the compiler must not create an immutable view of
storage that remains mutable through another live alias. Consequently, a
mutable pointer or slice does not generally convert implicitly to its immutable
counterpart. Static string literal storage is already immutable and may be
viewed through an immutable character slice.

## <a id="removing_with_cast"></a>Casts and Immutability

A cast can change the static type the compiler uses for an expression, but
it cannot make modification of genuinely immutable storage valid. Writing
through a cast that removes `immutable` has undefined behavior and may fail
on read-only storage.

A cast is therefore not an ownership or mutability transfer. Programs that
need mutable data must create or receive mutable storage explicitly.

## <a id="immutable_member_functions"></a>Immutable Member Functions

A struct or union method may declare an immutable receiver by writing
`immutable` after its parameter list. Such a method can be called on an
immutable value and cannot modify its fields.

```d
d
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

Overload resolution may distinguish mutable and immutable receiver methods.
The rejected postfix `const`, `inout`, and `shared` receiver forms are
not candidates.

## <a id="const_type"></a>Const Types

`const(Type)` and derived types containing `const` are supported when
their underlying types are supported. Qualification does not make an otherwise
rejected type available.

## <a id="const_member_functions"></a>Rejected `const` Methods

> **Rejected in Laser-D:**
>
> A member function cannot have a `const` receiver. Use a
> mutable receiver for a normal method or an `immutable` receiver for a value
> that is permanently immutable.

## <a id="inout"></a>Rejected `inout`

> **Rejected in Laser-D:**
>
> The `inout` qualifier, wildcard qualifier matching, and
> `inout` receiver/parameter/return forms are rejected. Laser-D has no need to
> abstract over a mutable/const/immutable qualifier family that it does not
> provide.

## <a id="shared"></a>Rejected `shared`

> **Rejected in Laser-D:**
>
> The `shared` qualifier is rejected as part of Laser-D's
> rejection of native D multithreading. C threading and atomic facilities may be
> used through explicit C interoperability.

### <a id="shared_cast"></a>Shared Casts

Casts cannot introduce or remove `shared`, because the qualifier itself
is unavailable in Laser-D source.

### <a id="shared_global"></a>Shared Global Variables

`shared` globals and shared module lifecycle functions are rejected.
Mutable global storage is independently rejected.

## <a id="combining_qualifiers"></a>Qualifier Composition

Because `immutable` is the only retained qualifier, Laser-D has no source
syntax for composing it with `const`, `inout`, or `shared`.
Immutability still composes normally with supported pointers, arrays, slices, aggregates, function signatures, aliases, and templates.

## <a id="implicit_qualifier_conversions"></a>Immutable Conversions

A mutable scalar or ordinary value-copyable aggregate expression may
initialize separate immutable value storage when the conversion copies the
value and leaves no mutable alias to the immutable destination.

An immutable value may be read, copied to another compatible immutable
value, passed to an immutable parameter or receiver, and explicitly converted
to a compatible scalar value where the ordinary conversion rules permit. It
does not implicitly convert to a mutable reference, pointer, or slice.

### <a id="unique-expressions"></a>Unique Expressions

Upstream D uses uniqueness analysis to permit some mutable-to-immutable
reference conversions. Laser-D's rejected allocation and owning-array features
remove the common implicit-uniqueness cases. No general ownership transfer is
implied: conversions involving pointers or slices must preserve the rule that
immutable storage has no mutable alias.

## <a id="importc-qualifiers"></a>ImportC Qualifiers

ImportC preserves C `const` and the frontend representation required for
the reviewed C baseline. Other C qualifications, including atomic forms, remain
subject to the ImportC audit. No ImportC qualifier enables corresponding
D-source syntax or semantics in a Laser-D module.

## <a id="conformance"></a>Conformance Boundary

Laser-D qualifier conformance consists of transitive `immutable`, local
runtime initialization, eligible static immutable initialization, immutable
receiver methods, and conversions that preserve permanent immutability.
Source-level `const`, `inout`, and `shared`, mutable aliases to immutable
storage, and module-lifecycle initialization are rejected.
