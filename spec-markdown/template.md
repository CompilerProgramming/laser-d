---
title: Templates
status: supported
source: ../spec/template.dd
---

# Templates

> **Laser-D normative:**
>
> Templates are part of Laser-D's compile-time programming
> model. Type, value, alias, and sequence parameters; overload selection;
> specialization; constraints; explicit and inferred instantiation; recursion;
> and cross-module instance emission are supported.

A template operates on already parsed declarations and expressions. It
does not create an exception to any Laser-D language rule: every declaration, type, expression, and statement produced by an instance must itself be valid
Laser-D.

## <a id="declarations"></a>Template Declarations

```text
TemplateDeclaration:
    template Identifier TemplateParameters Constraint[] { DeclDefs[] }

TemplateParameters:
    ( TemplateParameterList[] )

TemplateParameterList:
    TemplateParameter
    TemplateParameter , TemplateParameterList
```

A named template introduces a scope containing its parameters and body.
The body may contain supported aliases, manifest constants, functions, structs, unions, enums, and further templates.

```d
template Pointer(T)
{
    alias Pointer = T*;
}

static assert(is(Pointer!int == int*));
```

Multiple templates may share a name and form an overload set when their
parameters, specializations, or constraints distinguish them.

## <a id="template_instantiation"></a>Template Instantiation

### <a id="explicit_tmp_instantiation"></a>Explicit Instantiation

```text
TemplateInstance:
    Identifier ! TemplateArguments

TemplateArguments:
    ( TemplateArgumentList[] )
    TemplateSingleArgument

TemplateArgumentList:
    TemplateArgument
    TemplateArgument , TemplateArgumentList
```

`Name!(arguments)` explicitly selects and instantiates a matching
template. The short `Name!argument` form is available where the D grammar
accepts a single unambiguous argument.

Arguments are resolved at compile time. A failure to find one uniquely
best matching declaration is a compile-time error.

### <a id="common_instantiation"></a>Instance Identity

Instantiating the same template declaration with equivalent arguments
denotes the same semantic instance. The compiler may share generated code and
data according to the normal linkage and emission rules.

### <a id="instantiation_scope"></a>Scope

Names in the template declaration are resolved in their lexical scope.
Names supplied as template arguments retain their symbol identity. An
instantiation does not gain access to an enclosing runtime value unless the
instantiated declaration is otherwise permitted to carry that context;
Laser-D rejects hidden-context structs and named nested functions.

## <a id="parameters"></a>Template Parameters

```text
TemplateParameter:
    TemplateTypeParameter
    TemplateThisParameter
    TemplateValueParameter
    TemplateAliasParameter
    TemplateSequenceParameter
```

A parameter may have a specialization, a default argument, or both where
allowed by its parameter kind. Defaults are evaluated in the declaration's
scope.

### <a id="template_type_parameters"></a>Type Parameters

A type parameter accepts a supported Laser-D type. It may be specialized
to another type or pattern and may have a supported default type.

```d
template Element(T : T*)
{
    alias Element = T;
}

static assert(is(Element!(int*) == int));
```

Pattern deduction may bind additional identifiers appearing in the
specialization. A rejected type cannot be introduced merely because a template
could describe its pattern.

### <a id="template_this_parameter"></a>Template `this` Parameters

> **Supported in Laser-D:**
>
> A template `this` parameter on a struct or union member
> may infer the receiver type. It can distinguish mutable and immutable
> receivers using the supported type system.

It does not add an outer object reference, inheritance, a hidden context, or class/interface behavior. The instantiated member remains subject to the
ordinary receiver and function rules.

### <a id="template_value_parameter"></a>Value Parameters

A value parameter has a declared supported type and receives a value that
is known at compile time. It may have a value specialization and default.

```d
template PowerOfTwo(uint exponent)
{
    enum PowerOfTwo = 1u << exponent;
}

static assert(PowerOfTwo!5 == 32);
```

Values used as template arguments must be representable and valid for
compile-time evaluation. Runtime addresses or values with unsupported types do
not become valid template arguments.

### <a id="aliasparameters"></a>Alias Parameters

An alias parameter accepts a symbol, type, template, or compile-time value
that is valid for alias binding. It preserves the identity of a symbol rather
than copying its runtime value.

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

Alias parameters may be specialized, constrained, or given defaults.
Binding a rejected declaration does not make that declaration usable.

### <a id="variadic-templates"></a>Sequence Parameters

A final parameter written `Name...` accepts a compile-time sequence of
zero or more types, values, aliases, or mixtures accepted by the declaration.

```d
template Count(Items...)
{
    enum Count = Items.length;
}

static assert(Count!(int, long, 7) == 3);
```

A sequence supports compile-time length, indexing, slicing, expansion, and
iteration by supported compile-time constructs. It is not a runtime dynamic
array, does not allocate, and does not enable D runtime variadic functions.

A sequence parameter must be last. Function-template deduction may collect
remaining matching arguments into it.

### <a id="template_parameter_def_values"></a>Default Arguments

Omitted template arguments use their declared defaults after earlier
parameters have been bound. A default may depend on an earlier parameter but
must itself produce a supported argument.

## <a id="selection"></a>Selection and Specialization

Template selection considers parameter kinds, explicit specializations, deduced patterns, constraints, and overload ordering. The uniquely most
specialized viable declaration is selected.

Specializations may distinguish supported type structure, compile-time
values, aliases, and sequence shapes. Class inheritance and interface
conversion do not participate because those type families are unavailable.

## <a id="template_constraints"></a>Template Constraints

```text
Constraint:
    if ( Expression )
```

A constraint is evaluated at compile time after enough parameters have
been bound to evaluate it. A true constraint makes that candidate viable; a
false constraint removes it from the overload set.

```d
T larger(T)(T left, T right)
    if (is(T == int) || is(T == long))
{
    return left > right ? left : right;
}

static assert(larger(10, 20) == 20);
```

Constraints may use supported `is`, `typeof`, `__traits`, CTFE, and template facilities. They cannot perform compile-time file I/O, inject
source text, or rely on a rejected runtime service.

## <a id="implicit_template_properties"></a>Eponymous Templates

When a template contains a member with the same name, selecting the
template may directly denote that member. This supports type aliases, manifest
values, and other compile-time results.

```d
template Identity(T)
{
    alias Identity = T;
}

static assert(is(Identity!int == int));
```

## <a id="aggregate_templates"></a>Aggregate Templates

Struct and union templates are supported. Their fields, methods, constructors, operators, storage, and nesting must satisfy the corresponding
Laser-D aggregate rules.

```d
struct Pair(First, Second = First)
{
    First first;
    Second second;
}

static assert(is(typeof(Pair!(int, long).second) == long));
```

> **Excluded from Laser-D:**
>
> Class and interface templates are rejected because class and
> interface declarations are not part of Laser-D. An aggregate template cannot
> restore destructors, postblits, copy or move constructors, invariants, `alias this`, hidden contexts, or C++ struct linkage.

## <a id="function-templates"></a>Function Templates

A function template places template parameters before its ordinary
function parameters. It may be instantiated explicitly or inferred from the
call arguments.

### <a id="ifti"></a>Implicit Function Template Instantiation

IFTI deduces template parameters from the types and values of explicit
function arguments, applies defaults, checks constraints, and selects a unique
viable instance. Normal supported conversions occur only after deduction where
the D matching rules allow them.

### <a id="return-deduction"></a>Return-Type Deduction

An omitted function result type may be inferred from supported return
expressions. Deduction cannot produce a rejected type or a reference result.

> **Excluded from Laser-D:**
>
> Template functions cannot use `auto ref` parameters or
> returns. Parameters are limited to the separately supported Laser-D parameter
> forms, and reference return values are rejected.

## <a id="template_ctors"></a>Template Constructors

A supported struct may declare a templated constructor, and a struct
template may declare an ordinary constructor. Construction initializes the
destination in place through compiler-internal lowering; it does not expose a
source-level reference return.

Constructor delegation, class construction, destructors, postblits, and
copy or move constructors remain rejected.

## <a id="variable-template"></a>Enum and Variable Templates

Manifest enum templates and supported variable templates may depend on
template parameters. Any instantiated storage must follow the Laser-D global
and static-storage rules; a template does not permit mutable global state.

```d
enum doubled(int value) = value * 2;

static assert(doubled!21 == 42);
```

## <a id="alias-template"></a>Alias Templates

An alias template computes a type, symbol, template, or supported
compile-time value without introducing runtime storage.

```d
alias Pointer(T) = T*;

static assert(is(Pointer!int == int*));
```

## <a id="nested-templates"></a>Nested Templates

Templates may be nested in supported modules, templates, structs, unions, and functions where their instantiated declarations require no rejected hidden
runtime context. Lexical nesting affects name lookup but does not by itself
create a closure or outer aggregate pointer.

## <a id="recursive_templates"></a>Recursive Templates

A template may instantiate itself directly or indirectly when each
instantiation makes finite progress toward a terminating specialization or
constraint. Non-terminating or excessively deep instantiation is diagnosed by
the compiler's implementation limits.

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

## <a id="emission"></a>Instance Emission

> **Laser-D normative:**
>
> Template instances required by a root module are emitted
> without relying on the D runtime. Instances used across separately compiled
> modules retain the normal symbol identity, linkage, and duplicate-elimination
> rules of the unchanged frontend/backend interface.

Emission does not make an otherwise rejected declaration linkable.
Instantiated code must use supported functions, storage, types, and foreign
interfaces.

## <a id="compile-time"></a>Compile-Time Evaluation

Templates compose with CTFE, `static if`, `static foreach`, `static assert`, `typeof`, `is`, and the supported `__traits`
operations. Template arguments, constraints, initializers, and manifest values
may invoke supported CTFE functions.

`__ctfe` remains available to distinguish compile-time execution inside
a function. Compile-time execution does not grant additional language
capabilities.

## <a id="restrictions"></a>Cross-Cutting Restrictions

> **Excluded from Laser-D:** A template, constraint, or CTFE evaluation cannot restore:

- string mixin declarations, statements, expressions, or types,
- compile-time import expressions or other compile-time file I/O,
- classes, interfaces, associative arrays, vectors, or rejected scalar types,
- GC-backed allocation, array growth, or capturing delegates,
- exceptions, runtime assertions, contracts, or unit-test blocks,
- user-defined attributes, rejected qualifiers, or rejected parameter and return annotations,
- runtime type metadata, module lifecycle, global mutable state, threading features, or inline assembly.

`__traits(compiles)` may probe whether code follows these rules, but a
successful enclosing template declaration does not defer or suppress a
diagnostic for an actually instantiated rejected construct.
