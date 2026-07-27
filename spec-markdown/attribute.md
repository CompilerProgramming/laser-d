---
title: Attributes and declaration modifiers
status: restricted
source: ../spec/attribute.dd
---

# Attributes and declaration modifiers

Laser-D declaration modifiers specify linkage, import visibility, type
qualification, inference, storage, and parameter passing.

Each modifier is valid only on the declaration forms defined in this chapter or
its dedicated language chapter.

## Syntax

```text
AttributeSpecifier:
    LinkageAttribute :
    LinkageAttribute DeclarationBlock

DeclarationBlock:
    Declaration
    { Declarations }

DeclarationModifier:
    ImportVisibility
    const
    immutable
    auto
    static
    in
    out
    ref
```

A linkage attribute followed by `:` applies to the declarations which follow
in the same declaration list:

```d
extern(C):

int first(int value);
int second(int value);
```

A linkage attribute followed by a declaration block applies within that block:

```d
extern(C)
{
    int first(int value);
    int second(int value);
}
```

The attribute forms do not create a runtime object or hidden initialization.

## <a id="linkage"></a>Linkage

```text
LinkageAttribute:
    extern ( D )
    extern ( C )
    extern ( C ++ )
```

### Native linkage

`extern(D)` selects the native D-compatible ABI used by ordinary Laser-D
functions:

```d
extern(D) int nativeFunction(int value);
```

The attribute may be omitted for an ordinary function using native linkage.

### C linkage

`extern(C)` selects the target C ABI:

```d
extern(C) int cFunction(int value);
```

It controls the calling convention and symbol naming needed to link a
compatible C definition. C variadic functions and the executable entry point
also use C linkage.

## Import visibility

```text
ImportVisibility:
    private
    public
```

Import visibility controls re-export from a module.

A private import is available within the importing module:

```d
private import implementation;
```

A public import also exposes the imported module's visible declarations to
modules which import the current module:

```d
public import public_api;
```

An import without an explicit visibility modifier is private. The modules
chapter defines lookup and re-export behavior.

## Type qualification

`const` and `immutable` construct qualified types:

```d
alias ReadOnlyPointer = const(int)*;
immutable int permanent = 42;
```

`const` is an aliasable read-only view. `immutable` is permanently and
transitively unmodifiable. Their declaration, conversion, pointer, aggregate,
and receiver rules are defined by the type-qualifier chapter.

## Type inference

`auto` infers a type from a required initializer:

```d
int infer()
{
    auto value = 42;
    static assert(is(typeof(value) == int));
    return value;
}
```

The inferred type is fixed at compile time.

An `auto` function result is inferred from its reachable value-return
expressions, as defined by the functions chapter.

## Static immutable storage

`static immutable` declares deeply immutable static data with a compile-time
initializer:

```d
struct Constants
{
    static immutable int answer = 42;
}
```

Manifest `enum` constants also occupy no mutable runtime storage. Static
storage and initialization are defined by the declarations and qualifier
chapters.

`static import` is a separate import form which requires qualified member
access:

```d
static import geometry.matrix;
```

## Parameter modifiers

The function parameter modifiers are:

- `in` for an input value;
- `out` for caller-provided output storage; and
- `ref` for an alias to an initialized caller lvalue.

```d
void update(in int input, out int output, ref int state)
{
    output = input;
    state += input;
}
```

Their initialization, lvalue, lifetime, and calling rules are defined in the
functions chapter.

## Implicit function properties

Every Laser-D function and function type is:

- `nothrow`;
- `@nogc`;
- `@system`; and
- conservatively impure.

These are fixed properties of the function type. They apply to free functions,
methods, external declarations, pointers, delegates, literals, templates,
inferred functions, and compiler-generated helpers.

The properties are implicit and therefore add no source modifier to a function
declaration.
