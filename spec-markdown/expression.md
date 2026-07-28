---
title: Expressions
status: restricted
review-sources: ../spec/expression.dd
---

# Expressions

Expressions compute values, designate storage, call functions, and perform
explicit side effects. An expression is valid only when every type and language
facility it uses is part of Laser-D.

This chapter specifies the reviewed expression forms. Differences from D are
summarized in [D compatibility notes](d-compatibility.md). Expression forms
awaiting a decision are listed in [Feature status](../FEATURE_STATUS.md).

## Values and storage

An lvalue designates storage. Variables, mutable fields, pointer
dereferences, built-in indexing, and assignments are lvalues when their
underlying storage is mutable. Indexing a mutable slice designates its backing
storage; the slice itself does not own that storage.

Literals, manifest constants, and function results are values rather than
lvalues. Index operators return values; an overloaded index is changed through `opIndexAssign`,
`opIndexOpAssign`, or `opIndexUnary`.

Taking an address requires addressable storage. A pointer or slice does not own
or extend the lifetime of the storage it refers to.

## Core operators

The reviewed scalar expression operators are:

```text
Assignment:
    =
    +=  -=  *=  /=  %=
    &=  |=  ^=
    <<=  >>=

Logical:
    !
    &&
    ||

Conditional:
    condition ? whenTrue : whenFalse

Bitwise:
    &
    |
    ^
    ~
    <<
    >>

Comparison:
    ==
    !=
    is
    !is
    <
    <=
    >
    >=

Arithmetic:
    unary +
    unary -
    +
    -
    *
    /
    %
    ++
    --
```

The operands must have supported types and must satisfy the normal type
conversion rules. `&&` and `||` short-circuit. The conditional expression
evaluates only its selected result expression.

The left operand of assignment must be a modifiable lvalue. Simple assignment
converts the right operand to the destination type. Compound assignment
evaluates the destination as a single storage location, performs the selected
operation, and stores the result.

`is` and `!is` test representation identity. For pointers they compare
addresses. For slices they compare both pointer and length.

Modern struct operator overloads may provide the corresponding behavior for
value types. See [Operator overloading](operatoroverloading.md).

## Addresses and indirection

`&expression` produces a non-owning pointer to addressable storage.
`*pointer` designates the pointed-to storage. The programmer is responsible for
ensuring that the pointer is non-null, correctly aligned, within the lifetime
of the referred object, and valid for the operation.

Pointer indexing and explicit pointer slicing are supported systems
operations.

## Explicit conversion

```text
CastExpression:
    cast ( Type ) UnaryExpression
```

`cast(T) expression` explicitly converts an expression to supported type `T`
when that conversion has been reviewed. Scalar numeric conversions are
supported. A modern `opCast` overload may define conversion of a struct value.

A cast target must be a supported Laser-D type and qualifier.

## Calls

Functions, function pointers, delegates, struct constructors, templates,
operator calls, and UFCS calls use an explicit parenthesized argument list.
Arguments bind positionally and are evaluated once. An omitted trailing
parameter must have a supported default argument.

```text
CallExpression:
    PostfixExpression ( )
    PostfixExpression ( ArgumentList )

ArgumentList:
    AssignExpression
    AssignExpression ,
    AssignExpression , ArgumentList
```

## Indexing and slicing

```text
IndexOperation:
    [ ArgumentList ]

SliceOperation:
    [ ]
    [ AssignExpression .. AssignExpression ]
```

Fixed arrays, slices, and pointers support one-dimensional indexing. Within a
built-in index or slice operation, `$` denotes the current length when the
operand has one.

Slicing a fixed array, slice, or explicit pointer range produces a non-owning
slice. The backing storage must remain alive for every use of that slice.

Structs may provide one-dimensional and multidimensional indexing, slicing,
assignment, compound assignment, unary mutation, and `$` through the modern
operator hooks. See [Arrays](types.md#arrays-and-slices) and
[Operator overloading](operatoroverloading.md).

## Primary expressions

The reviewed primary forms are:

```text
PrimaryExpression:
    Identifier
    . Identifier
    TemplateInstance
    . TemplateInstance
    $
    LiteralExpression
    FundamentalType ( ArgumentList? )
    Typeof
    IsExpression
    ( Expression )
    SpecialKeyword
    TraitsExpression

LiteralExpression:
    this
    null
    true
    false
    IntegerLiteral
    FloatLiteral
    CharacterLiteral
    StringLiteral
    FunctionLiteral
```

Root-qualified names, template instances, parentheses, properties of supported
types, scalar construction, `typeof`, `is`, traits, and non-capturing function
literals are supported subject to their feature-specific rules.

### `this`

Within a struct or union constructor or instance method, `this` denotes the
current value. It may qualify a field, be passed or returned by value, have its
address taken, and form a delegate to a method. `typeof(this)` yields the
receiver type without evaluating it. A template `this` parameter may infer a
mutable or immutable receiver type.

A pointer or delegate derived from `this` does not own or extend the receiver
lifetime.

### `null`

`null` converts to a pointer, slice, function pointer, or delegate.

### String literals

String literals occupy immutable, compiler-provided static storage and are
viewed through non-owning character slices. Their operations are specified in
[Arrays](types.md#arrays-and-slices).

### Function literals

```text
FunctionLiteral:
    function ReturnType? Parameters FunctionLiteralBody
    delegate ReturnType? Parameters FunctionLiteralBody
    Parameters FunctionLiteralBody
    Identifier => AssignExpression

FunctionLiteralBody:
    => AssignExpression
    FunctionBody
```

Non-capturing function and delegate literals are supported. Parameter and
return types may be inferred at compile time. Inference cannot introduce an
excluded type or function feature.

### `is` expressions

```text
IsExpression:
    is ( Type )
    is ( Type : TypeSpecialization )
    is ( Type == TypeSpecialization )
    is ( Type Identifier )
    is ( Type Identifier : TypeSpecialization )
    is ( Type Identifier == TypeSpecialization )
```

An `is` expression performs a compile-time validity, equivalence, conversion,
category, or pattern-deduction query over the supported type system.

### Special keywords

```text
SpecialKeyword:
    __FILE__
    __FILE_FULL_PATH__
    __MODULE__
    __LINE__
    __FUNCTION__
    __PRETTY_FUNCTION__
```

These keywords provide compile-time source-location or symbol information.
They require no runtime service.

## Compile-time assertions

```text
StaticAssert:
    static assert ( AssignExpression ) ;
    static assert ( AssignExpression , AssignExpression ) ;
```

`static assert` evaluates its condition and optional message during
compilation. It emits no runtime code. ImportC retains C `_Static_assert`.
