---
title: Template mixins
status: supported
source: ../spec/template-mixin.dd
---

# Template mixins

A mixin-template declaration defines a parameterized declaration body. A
template-mixin instance inserts an instance of that body into a declaration
scope.

Template mixins operate on declarations parsed at their original source
location. Differences from D mixin facilities are summarized in
[D compatibility notes](d-compatibility.md).

## Declaration

```text
TemplateMixinDeclaration:
    mixin template Identifier TemplateParameters Constraint? { Declarations }
```

A mixin template uses the ordinary type, value, alias, and sequence template
parameters. Defaults, specializations, and constraints follow the rules in
[Templates](template.md).

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

## Instantiation

```text
TemplateMixin:
    mixin Identifier TemplateArguments? ;
    mixin Identifier TemplateArguments? InstanceName ;
```

An unnamed instance inserts its declarations directly into the receiving
scope.

```d
struct Container
{
    mixin Members!(int, 7);
}

static assert(Container.init.value == 7);
```

A named instance places the inserted declarations beneath the instance name.

```d
union Storage
{
    mixin Members!uint namedMembers;
}

static assert(is(typeof(Storage.init.namedMembers.value) == uint));
```

Template arguments may be omitted when the declaration has no required
parameters.

## Insertion scopes

Template mixins may insert declarations:

- at module scope;
- in a struct or union;
- within another template; and
- in function-local declaration scope.

At module scope, a mixin may introduce aliases, manifest constants, functions,
structs, unions, enums, and templates.

Within a struct or union, it may introduce fields, methods, constructors,
operators, aliases, manifest constants, and nested declarations.

Within a template, inserted declarations may depend on the enclosing
compile-time parameters. Within a function, a mixin may introduce local
declarations.

## Scope and name lookup

Template arguments and names referenced by a mixin-template declaration use
ordinary template name lookup. Inserted declarations become members of the
receiving scope or of the explicit named instance.

Name conflicts follow the ordinary declaration and overload rules. A named
instance provides a distinct scope for its inserted members.

## Composition

A mixin-template body may instantiate supported templates and template
mixins. Recursive template composition must terminate within the compiler's
template-instantiation limits.

Methods and operator hooks inserted into a struct behave as if they were
declared directly in that struct.
