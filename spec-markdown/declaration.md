---
title: Declarations
status: restricted
source: ../spec/declaration.dd
---

# Declarations

> **Laser-D normative:**
>
> Laser-D declarations introduce functions, variables, aliases, structs, unions, enums, imports, templates, and compile-time
> declarations. A declaration never enables a type, attribute, initializer, or
> storage model rejected by its own normative chapter.

## <a id="grammar"></a>Grammar

A *Declaration* may occur at module scope, in an aggregate, or as a
DeclarationStatement in a function. The enclosing scope
determines which alternatives are valid.

```text
Declaration:
    FuncDeclaration
    VarDeclarations
    AliasDeclaration
    AliasAssign
    AggregateDeclaration
    EnumDeclaration
    ImportDeclaration
    ConditionalDeclaration
    StaticForeachDeclaration
    StaticAssert
    TemplateDeclaration
    TemplateMixinDeclaration
    TemplateMixin
```

Within ConditionalDeclaration, only compile-time forms
classified as supported by the conditional-compilation chapter are available.
In particular, retaining `static if` for templates does not implicitly
classify `version` or `debug`.

### <a id="aggregates"></a>Aggregate Declarations

```text
AggregateDeclaration:
    StructDeclaration
    UnionDeclaration
```

> **Excluded from Laser-D:**
>
> Native D classes and interfaces are not declaration
> alternatives. C, C++, and Objective-C class declarations are also unavailable.
> ImportC struct, union, and enum declarations follow the ImportC grammar.

## <a id="variable-declarations"></a>Variable Declarations

```text
VarDeclarations:
    StorageClasses[] BasicType TypeSuffixes[] IdentifierInitializers ;
    AutoDeclaration

IdentifierInitializers: DeclaratorIdentifierList
    IdentifierInitializer
    IdentifierInitializer , IdentifierInitializers

IdentifierInitializer: DeclaratorIdentifier
    Identifier
    Identifier TemplateParameters[] = Initializer
    BitfieldDeclarator
    BitfieldDeclarator = Initializer

BitfieldDeclarator:
    : AssignExpression
    Identifier : ConditionalExpression

Declarator: VarDeclarator
    TypeSuffixes[] Identifier
```

A declaration may declare several identifiers of the same type. Each
identifier occupies distinct storage unless it is an alias. A variable without
an initializer receives its type's `.init` value.

```d
int count;
int left = 1
right = 2;
int* first
second;       // both are pointers
int[4] values;            // fixed-size inline storage
```

Bit-field declarators are valid only as struct or union fields and are
defined by the struct chapter.

### <a id="storage-classes"></a>Storage Classes

```text
StorageClasses:
    StorageClass
    StorageClass StorageClasses

StorageClass:
    LinkageAttribute
    enum
    static
    extern
    auto
    immutable
    ref
```

This grammar lists storage-class tokens used by declarations; their
placement and combinations remain constrained by the referenced chapters.
For example, `static` does not permit mutable static storage, and `ref`
does not permit reference return values or `auto ref`.

> **Excluded from Laser-D:**
>
> `const`, `inout`, `shared`, `__gshared`, `synchronized`, `scope`, `lazy`, `return`, `final`, `abstract`, `override`, explicit `nothrow`, explicit `@nogc`, function safety attributes, `pure`, `@live`, `@property`, and
> user-defined attributes are not storage-class alternatives in Laser-D.
> Remaining built-in attributes are classified by the attributes chapter.

### <a id="auto-declaration"></a>Type Inference

```text
AutoDeclaration:
    StorageClasses AutoAssignments ;

AutoAssignments:
    AutoAssignment
    AutoAssignments , AutoAssignment

AutoAssignment:
    Identifier TemplateParameters[] = NonVoidInitializer
```

`auto`, `immutable`, and manifest `enum` declarations may infer
their type from a non-void initializer. Inference is compile-time and the
inferred type is fixed. Every inferred declaration requires an initializer.

```d
auto count = 3;                 // int
immutable limit = 10;           // immutable(int)
enum width = 4;                 // manifest constant
auto text = "Laser-D";          // immutable(char)[]
```

Inference does not make a rejected expression or type valid. In particular, it cannot introduce GC-backed array literals, associative arrays, classes, `real`, imaginary types, complex types, or capturing delegates.

## <a id="initialization"></a>Initialization

```text
Initializer:
    VoidInitializer
    NonVoidInitializer

NonVoidInitializer:
    ArrayInitializerArrayInitializer
    StructInitializerStructInitializer
    AssignExpressionExpInitializer

VoidInitializer:
    void
```

Expression, fixed-array, and struct initializers are supported when their
result type and operations are supported. An initializer does not allocate
storage independently of the declared object.

A local variable may use `void` initialization to suppress its default
initialization. Reading any part of that variable before it has been assigned a
valid value has implementation-defined results and may be undefined for the
underlying machine operation.

### <a id="global_static_init"></a>Global and Static Storage

> **Laser-D normative:**
>
> Laser-D source cannot declare mutable module, global, function-static, or aggregate-static storage. Manifest constants and deeply
> `immutable` static data are supported when their initializers are evaluable
> at compile time. ImportC globals are exempt.

Laser-D has no runtime initialization pass and no module constructors or
destructors. A static initializer therefore cannot require executable startup
or shutdown code.

```d
enum bufferSize = 256;
immutable int tableEntry = 7;

// int mutableGlobal;       // rejected
// static int cachedValue;  // rejected
```

## <a id="alias"></a>Alias Declarations

```text
AliasDeclaration:
    alias AliasAssignments ;

AliasAssignments:
    AliasAssignment
    AliasAssignments , AliasAssignment

AliasAssignment:
    Identifier TemplateParameters[] = Type
    Identifier TemplateParameters[] = FunctionLiteral
    Identifier TemplateParameters[] = Type Parameters
```

An alias introduces another name for a supported type, variable, function, module, template, template instance, manifest constant, or overload set. It
does not create storage or a distinct type.

```d
alias Index = uint;

int value;
alias current = value;

template Element(T)
{
    alias Element = T;
}
```

Aliasing a symbol does not bypass restrictions on that symbol. In
particular, aliases cannot introduce an excluded type, and `alias this` is a
different declaration which Laser-D rejects.

### <a id="alias-function"></a>Function Type Aliases

Supported function types may be aliased, including their parameter types
and default arguments. The alias does not change the function calling
convention or permit rejected parameter and return annotations.

```d
alias Compare = int function(int left, int right);
alias Scale = int function(int value, int factor = 2);
```

### <a id="AliasAssign"></a>Compile-Time Alias Assignment

```text
AliasAssign:
    Identifier = Type

AliasReassignment:
    Identifier = Type
    Identifier = FunctionLiteral
```

An alias declared inside a template may be reassigned within that same
template before its value is otherwise used. This is compile-time template
machinery and creates no runtime mutation.

## <a id="extern"></a>Extern Declarations

An `extern` variable declaration allocates no Laser-D storage. The
symbol must be supplied by another object file with compatible linkage and
type. C linkage is the normal use.

```d
extern(C) int externalFunction(int);
extern extern(C) int externalVariable;
```

An external declaration does not make unsupported C++ class or Objective-C
interoperability available. ImportC is the preferred way to consume supported C
declarations directly.

## <a id="ref-storage"></a>Reference Storage

A `ref` parameter aliases caller-provided storage and is described in
the functions chapter. A local ref variable may alias an existing lvalue; it
does not allocate or own storage.

### <a id="ref-variables"></a>Local Reference Variables

```d
void increment(ref int value)
{
    ++value;
}

void example()
{
    int value;
    ref int aliasToValue = value;
    increment(aliasToValue);
}
```

> **Excluded from Laser-D:**
>
> Reference return values and `auto ref` inference are not
> part of Laser-D. A function result is always returned by value.

### <a id="methods-returning-qualified"></a>Qualified Function Results

> **Excluded from Laser-D:**
>
> Laser-D rejects `const` and `inout` function qualifiers.
> An `immutable` result is a qualified value type, not a function storage
> class. Function result annotations cannot be used to create reference returns.
