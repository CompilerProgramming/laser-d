---
title: Templates
status: supported
source: ../spec/template.dd
---

# Templates

Templates are Laser-D's compile-time parameterization mechanism. They support
type, value, alias, and sequence parameters; overloads; specialization;
constraints; explicit and inferred instantiation; recursion; and cross-module
instance emission.

A template body consists of normal parsed Laser-D declarations and
expressions. Differences from D template use are summarized in
[D compatibility notes](d-compatibility.md).

## Template declarations

```text
TemplateDeclaration:
    template Identifier TemplateParameters Constraint? { Declarations }

TemplateParameters:
    ( )
    ( TemplateParameterList )

TemplateParameterList:
    TemplateParameter
    TemplateParameter , TemplateParameterList
```

A named template introduces a scope containing its parameters and body. The
body may contain aliases, manifest constants, functions, structs, unions,
enums, and further templates.

```d
template Pointer(T)
{
    alias Pointer = T*;
}

static assert(is(Pointer!int == int*));
```

Templates with the same name form an overload set when their parameters,
specializations, or constraints distinguish them.

## Instantiation

```text
TemplateInstance:
    Identifier ! TemplateArguments

TemplateArguments:
    ( )
    ( TemplateArgumentList )
    TemplateSingleArgument
```

`Name!(arguments)` explicitly selects and instantiates a matching template.
The short `Name!argument` form is available for a single unambiguous argument.
A unique best matching declaration must exist.

Equivalent arguments to the same template declaration denote the same
semantic instance. Names in the declaration resolve in its lexical scope, and
symbols supplied as arguments preserve their identity.

## Parameters

```text
TemplateParameter:
    TemplateTypeParameter
    TemplateThisParameter
    TemplateValueParameter
    TemplateAliasParameter
    TemplateSequenceParameter
```

A parameter may have a specialization, a default argument, or both where its
kind permits them. A default may depend on an earlier parameter.

### Type parameters

A type parameter accepts a supported type. It may specialize another type or
type pattern and may have a default.

```d
template Element(T : T*)
{
    alias Element = T;
}

static assert(is(Element!(int*) == int));
```

Pattern deduction may bind identifiers appearing in the specialization.

### Template `this` parameters

A template `this` parameter on a struct or union member infers the receiver
type. It can distinguish mutable and immutable receivers.

### Value parameters

A value parameter has a declared type and receives a compile-time-known value.
It may have a value specialization and a default.

```d
template PowerOfTwo(uint exponent)
{
    enum PowerOfTwo = 1u << exponent;
}

static assert(PowerOfTwo!5 == 32);
```

### Alias parameters

An alias parameter accepts a type, symbol, template, or compile-time value. It
preserves symbol identity.

```d
int increment(int value)
{
    return value + 1;
}

template Apply(alias operation, int value)
{
    enum Apply = operation(value);
}

static assert(Apply!(increment, 4) == 5);
```

Alias parameters may have specializations, constraints, and defaults.

An `is` expression that pattern-matches an instantiated template may bind an
alias parameter to the matched template argument:

```d
struct Holder(alias value)
{
}

static if (is(Holder!int == Holder!argument, alias argument))
    static assert(is(argument == int));
```

### Sequence parameters

A final parameter written `Name...` accepts a compile-time sequence of zero or
more types, values, aliases, or mixtures accepted by the declaration.

```d
template Count(Items...)
{
    enum Count = Items.length;
}

static assert(Count!(int, long, 7) == 3);
```

A sequence supports compile-time length, indexing, slicing, expansion, and
iteration. Function-template deduction may collect remaining matching
arguments into a final sequence parameter.

## Selection and specialization

Template selection considers parameter kinds, explicit specializations,
deduced patterns, constraints, and overload ordering. The uniquely most
specialized viable declaration is selected.

Specializations may distinguish type structure, compile-time values, aliases,
and sequence shapes.

## Constraints

```text
Constraint:
    if ( Expression )
```

A constraint is evaluated at compile time after enough parameters have been
bound. A true constraint makes the candidate viable; a false constraint
removes it from the overload set.

```d
T larger(T)(T left, T right)
    if (is(T == int) || is(T == long))
{
    return left > right ? left : right;
}

static assert(larger(10, 20) == 20);
```

Constraints may use `is`, `typeof`, supported `__traits`, CTFE, and other
templates.

## Eponymous templates

When a template contains a member with the same name, selecting the template
directly denotes that member.

```d
template Identity(T)
{
    alias Identity = T;
}

static assert(is(Identity!int == int));
```

Eponymous members may provide types, aliases, manifest values, or other
compile-time results.

## Aggregate templates

Struct and union declarations may have template parameters. Their fields,
methods, constructors, and operators follow the ordinary aggregate rules.

```d
struct Pair(First, Second = First)
{
    First first;
    Second second;
}

static assert(is(typeof(Pair!(int, long).second) == long));
```

A template may also produce an enum declaration.

## Function templates

A function template places template parameters before its ordinary function
parameters. It may be instantiated explicitly or inferred from a call.

Implicit function template instantiation deduces parameters from explicit
arguments, applies defaults, evaluates constraints, and selects one viable
instance. Normal argument conversions occur after deduction where the matching
rules permit them.

An omitted function result type is inferred from its return expressions.

## Templated constructors

A struct may declare a templated constructor, and a struct template may
declare an ordinary constructor.

```d
struct Converted
{
    int value;

    this(T)(T initial)
    {
        value = cast(int) initial;
    }
}

static assert(Converted(cast(short) 9).value == 9);
```

Construction initializes the destination value in place.

## Enum, variable, and alias templates

An enum template computes a manifest value:

```d
enum doubled(int value) = value * 2;

static assert(doubled!21 == 42);
```

A variable template produces storage according to the ordinary declaration and
storage-duration rules.

An alias template computes a type, symbol, template, or compile-time value:

```d
alias Pointer(T) = T*;

static assert(is(Pointer!int == int*));
```

## Nested and recursive templates

Templates may be nested in modules, templates, structs, unions, and functions.
Lexical nesting controls name lookup.

A template may instantiate itself directly or indirectly. Recursive
instantiation must reach a terminating specialization or constraint within the
compiler's implementation limits.

```d
template Factorial(uint value)
{
    enum Factorial = value * Factorial!(value - 1);
}

template Factorial(uint value : 0)
{
    enum Factorial = 1;
}

static assert(Factorial!5 == 120);
```

## Instance emission

Template instances required by a root module are emitted without a D runtime.
Instances used across separately compiled modules preserve semantic identity,
linkage, and the duplicate-elimination behavior of the compiler toolchain.

## Compile-time execution

Templates compose with CTFE, `static if`, `static foreach`, `static assert`,
`typeof`, `is`, and supported `__traits` operations. Arguments, constraints,
initializers, and manifest values may call CTFE functions.

Within a function, `__ctfe` is true during compile-time execution and false
during runtime execution.
