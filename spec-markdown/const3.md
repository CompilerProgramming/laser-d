# Type qualifiers

Laser-D has two type qualifiers:

- `const`, an aliasable read-only view; and
- `immutable`, a permanently unmodifiable value and object graph.

Both qualifiers are transitive. Qualifying a pointer, slice, fixed array, or
aggregate qualifies its reachable components and fields.

## Syntax

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

## `const`

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

### Const parameters and fields

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

## `immutable`

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

### Local initialization

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

### Static immutable storage

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

## Derived qualified types

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

## Qualifier conversions

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

## Casts

A cast changes the static type used for an expression. It does not change the
physical mutability, ownership, or lifetime of the underlying storage.

Modifying genuinely immutable storage through a cast which removes
`immutable` has undefined behavior. The storage may reside in read-only memory,
and the compiler may optimize under the assumption that it never changes.

Code which needs mutable data creates or receives mutable storage explicitly.

## Immutable receiver methods

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

## ImportC qualifiers

ImportC preserves C `const` in translated declarations. The resulting types
use the target C ABI and can be passed across the C boundary.

Other C qualification and atomic rules are defined only where the reviewed
ImportC surface specifies them.
