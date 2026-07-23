---
title: Template mixins
status: supported
source: ../spec/template-mixin.dd
---

# Template Mixins

> **Laser-D normative:**
>
> Template mixins compose already parsed declarations.
> A mixin-template declaration defines a parameterized declaration body, and a
> template-mixin instantiation inserts an instance of that body into a supported
> declaration scope.

Template mixins are distinct from string mixins. They do not construct
source text, re-run the parser, or permit a string to become a declaration, statement, expression, or type.

## <a id="grammar"></a>Grammar

```text
TemplateMixinDeclaration:
    mixin template Identifier TemplateParameters Constraint[] { DeclDefs[] }

TemplateMixin:
    mixin MixinTemplateName TemplateArguments[] Identifier[] ;
    mixin Identifier = MixinTemplateName TemplateArguments[] ;

MixinTemplateName:
    . MixinQualifiedIdentifier
    MixinQualifiedIdentifier
    Typeof . MixinQualifiedIdentifier

MixinQualifiedIdentifier:
    Identifier
    Identifier . MixinQualifiedIdentifier
    TemplateInstance . MixinQualifiedIdentifier
```

## <a id="declarations"></a>Mixin-Template Declarations

A declaration begins with `mixin template`, has the ordinary supported
template parameter forms and optional constraint, and contains declarations.
It can be instantiated only as a template mixin.

```d
mixin template Members(T, T initial = T.init)
{
    T value = initial;

    T read()
    {
        return value;
    }
}
```

Type, value, alias, and sequence parameters, defaults, specializations, and constraints follow the Laser-D template rules. The declarations in the
body are checked under the ordinary Laser-D rules when instantiated.

## <a id="instantiation"></a>Instantiation

A template mixin is instantiated with `mixin Name!(arguments);`.
Arguments may be omitted when the declaration requires none. The selected
template must be a mixin-template declaration or an ordinary template whose
body is valid for mixin insertion.

```d
struct Container
{
    mixin Members!(int, 7);
}

static assert(Container.init.value == 7);
```

An unnamed instance inserts its members directly into the receiving scope.
A named instance places the inserted declarations under that instance name.

```d
union Storage
{
    mixin Members!uint namedMembers;
}

static assert(is(typeof(Storage.init.namedMembers.value) == uint));
```

## <a id="supported-scopes"></a>Supported Scopes

Template mixins may insert supported declarations at module scope, in
structs and unions, within templates, and in function-local declaration
scope.

- At module scope they may introduce supported declarations such as aliases, manifest constants, functions, structs, unions, enums, and templates.
- In a struct or union they may introduce supported fields, methods, constructors, operators, aliases, manifest constants, and nested declarations.
- Within another template their declarations may depend on the enclosing template's compile-time parameters.
- In a function they may introduce supported local declarations that do not require a rejected hidden context or named nested function.

Class and interface scopes do not exist in Laser-D. ImportC declarations
remain governed by the separate ImportC rules.

## <a id="mixin_scope"></a>Scope and Name Lookup

Template arguments and names referenced by the mixin-template declaration
are resolved according to the ordinary template rules. Inserted declarations
become members of the receiving scope, or of the explicit named mixin instance
when one is supplied.

Name conflicts are diagnosed through ordinary declaration and overload
rules. Naming a mixin instance can separate otherwise conflicting inserted
member names.

Lexical availability does not authorize hidden runtime capture. A local
instantiation may use compile-time names visible at that point, but any
inserted runtime declaration must still satisfy the closure, nested-function, and hidden-context restrictions.

## <a id="composition"></a>Composition

A mixin-template body may instantiate other supported templates and
template mixins. Recursive composition must terminate within the compiler's
normal template-instantiation limits.

A template mixin may provide methods or operator hooks for a supported
struct. Those declarations behave exactly as if written directly in that
struct and receive no additional privileges.

## <a id="excluded-content"></a>Excluded Content

> **Excluded from Laser-D:** A template mixin cannot introduce or restore:

- classes, interfaces, or C++ structs,
- struct destructors, postblits, copy or move constructors, invariants, or `alias this`,
- named nested functions, capturing delegates, or hidden-context structs,
- mutable global or static storage, module lifecycle functions, or threading features,
- GC-backed arrays, associative arrays, allocation, or rejected types and qualifiers,
- contracts, runtime assertions, exceptions, unit-test blocks, inline assembly, or rejected attributes,
- any other declaration excluded by the Laser-D specification.

Rejection applies when the invalid declaration is instantiated. Placing
rejected syntax in a template does not make it part of Laser-D.

## <a id="string-mixins"></a>String Mixins (Excluded)

> **Excluded from Laser-D:**
>
> The following forms are not template mixins and remain
> rejected:

```d
mixin("int generated;");
mixin("1 + 2");
mixin("int");
```

Laser-D never reparses a compile-time string as language syntax. Template
mixins remain supported because their declaration bodies were parsed normally
at their original source locations.
