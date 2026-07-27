---
title: Declarations
status: restricted
source: ../spec/declaration.dd
---

# Declarations

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

Functions, structs and unions, enums, imports, conditional compilation,
templates, and template mixins are defined in their respective chapters.

## Variable declarations

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
supported value aggregates as defined by the corresponding type chapters.

Struct and union fields use the same basic declaration form. Bit-field
declarators are available only for fields and are defined by the structs and
unions chapter.

## Type inference

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

## Initializers

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
storage. The detailed rules are defined by the arrays and structs chapters.

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

### Void initialization

A local variable may use `void` initialization to suppress initialization:

```d
int value = void;
```

The program must assign a valid value before reading the variable. `void`
initialization does not alter the variable's type or storage duration.

## Manifest constants

An `enum` declaration without an enum type declares a manifest constant:

```d
enum columns = 4;
enum cells = columns * columns;
```

A manifest constant is evaluated at compile time, occupies no mutable runtime
storage, and may be used wherever a compile-time value is required.

Named enum types and their members are defined in the enums chapter.

## Static storage

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

## Alias declarations

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

## External function declarations

An external function declaration introduces a callable symbol whose definition
is provided by another object file or library:

```d
extern(C) int externalFunction(int value);
```

The declaration emits no Laser-D definition for the symbol. Calls use the
declared type and linkage, which must match the foreign definition.

`extern(C)` is the normal interface to C libraries. ImportC may be used to
translate reviewed C declarations from a preprocessed C source file.
