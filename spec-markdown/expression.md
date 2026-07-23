---
title: Expressions
status: restricted
source: ../spec/expression.dd
---

# Expressions

> **Laser-D normative:**
>
> Expressions compute values, select storage, call functions, and perform explicit side effects using supported Laser-D types. Expression
> syntax never restores an excluded type, allocation model, runtime service, or
> implicit function call.

## <a id="Expression"></a>Expression Grammar

```text
Expression:
    CommaExpression

CommaExpression:
    AssignExpression
    CommaExpression , AssignExpression

AssignExpression:
    ConditionalExpression
    ConditionalExpression = AssignExpression
    ConditionalExpression += AssignExpression
    ConditionalExpression -= AssignExpression
    ConditionalExpression *= AssignExpression
    ConditionalExpression /= AssignExpression
    ConditionalExpression %= AssignExpression
    ConditionalExpression &= AssignExpression
    ConditionalExpression |= AssignExpression
    ConditionalExpression ^= AssignExpression
    ConditionalExpression ~= AssignExpression
    ConditionalExpression <<= AssignExpression
    ConditionalExpression >>= AssignExpression
    ConditionalExpression >>>= AssignExpression
    ConditionalExpression ^^= AssignExpression

ConditionalExpression:
    OrOrExpression
    OrOrExpression ? Expression : ConditionalExpression

OrOrExpression:
    AndAndExpression
    OrOrExpression || AndAndExpression

AndAndExpression:
    OrExpression
    AndAndExpression && OrExpression

OrExpression:
    XorExpression
    OrExpression | XorExpression

XorExpression:
    AndExpression
    XorExpression ^ AndExpression

AndExpression:
    CmpExpression
    AndExpression & CmpExpression

CmpExpression:
    EqualExpression
    IdentityExpression
    RelExpression
    InExpression
    ShiftExpression

EqualExpression:
    ShiftExpression == ShiftExpression
    ShiftExpression != ShiftExpression

IdentityExpression:
    ShiftExpression is ShiftExpression
    ShiftExpression ! is ShiftExpression

RelExpression:
    ShiftExpression < ShiftExpression
    ShiftExpression <= ShiftExpression
    ShiftExpression > ShiftExpression
    ShiftExpression >= ShiftExpression

InExpression:
    ShiftExpression in ShiftExpression
    ShiftExpression ! in ShiftExpression

ShiftExpression:
    AddExpression
    ShiftExpression << AddExpression
    ShiftExpression >> AddExpression
    ShiftExpression >>> AddExpression

AddExpression:
    MulExpression
    AddExpression + MulExpression
    AddExpression - MulExpression
    AddExpression ~ MulExpression

MulExpression:
    UnaryExpression
    MulExpression * UnaryExpression
    MulExpression / UnaryExpression
    MulExpression % UnaryExpression

UnaryExpression:
    & UnaryExpression
    ++ UnaryExpression
    -- UnaryExpression
    * UnaryExpression
    - UnaryExpression
    + UnaryExpression
    ! UnaryExpression
    ComplementExpression
    CastExpression
    PowExpression

ComplementExpression:
    ~ UnaryExpression

CastExpression:
    cast ( Type ) UnaryExpression

PowExpression:
    PostfixExpression
    PostfixExpression ^^ UnaryExpression

PostfixExpression:
    PrimaryExpression
    PostfixExpression . Identifier
    PostfixExpression . TemplateInstance
    PostfixExpression ++
    PostfixExpression --
    PostfixExpression ( NamedArgumentList[] )
    TypeCtors[] BasicType ( NamedArgumentList[] )
    PostfixExpression IndexOperation
    PostfixExpression SliceOperation

ArgumentList:
    AssignExpression
    AssignExpression ,
    AssignExpression , ArgumentList

NamedArgumentList:
    NamedArgument
    NamedArgument ,
    NamedArgument , NamedArgumentList

NamedArgument:
    Identifier : AssignExpression
    AssignExpression

IndexOperation:
    [ ArgumentList ]

SliceOperation:
    [ ]
    [ Slice ]
    [ Slice , ]

Slice:
    AssignExpression
    AssignExpression , Slice
    AssignExpression .. AssignExpression
    AssignExpression .. AssignExpression , Slice
```

## <a id="definitions-and-terms"></a>Values and Storage

### <a id=".define-lvalue"></a>Lvalues

An lvalue designates writable or addressable storage. Variables, mutable
fields, pointer dereferences, built-in array indexing, and assignments are
lvalues where their underlying storage is mutable. A slice value is not an
owner, but indexing a mutable slice designates its backing storage.

Function results are values, not lvalues, because Laser-D rejects reference
returns. Operator overloads likewise return values; index mutation uses
`opIndexAssign`, `opIndexOpAssign`, or `opIndexUnary` rather than a
reference-returning `opIndex`.

### <a id=".define-rvalue"></a>Rvalues

Literals, manifest constants, function results, and other expressions not
designating storage are rvalues. Taking an address and binding a local
`ref` variable require an lvalue.

### <a id=".define-full-expression"></a>Full Expressions

A full expression is an expression not contained within another expression.
Temporary scalar and aggregate values live until the end of their full
expression. Laser-D has no destructor or postblit hook to run implicitly at
that boundary.

## <a id="order-of-evaluation"></a>Evaluation Order

Ordinary binary operands are evaluated left to right. `&&` and `||`
evaluate the right operand only when required. The conditional operator
evaluates its condition and then exactly one branch. D-linkage call targets and
arguments are evaluated left to right; foreign linkage follows the applicable
ABI.

## <a id="assign_expressions"></a>Assignment

### <a id="simple_assignment_expressions"></a>Simple Assignment

The left operand must be a modifiable lvalue. The right operand converts to
the destination type. Struct assignment copies value storage without a
user-defined postblit. Fixed-array and slice assignment follow the arrays
chapter; assignment cannot resize a slice.

### <a id="assignment_operator_expressions"></a>Compound Assignment

`a op= b` evaluates `a` once, performs the corresponding operation, and stores the converted result. Modern struct overloads use the operator
overloading hooks defined by that chapter.

## <a id="logical_expressions"></a>Logical and Conditional Expressions

`!`, `&&`, and `||` use Boolean conversion. The latter two
short-circuit. `condition ? yes : no` evaluates only the selected branch and
produces their common supported type.

## <a id="bitwise_expressions"></a>Bitwise and Shift Expressions

`&`, `|`, `^`, `~`, `<<`, `>>`, and `>>>` operate on
integral values after the integer conversions defined by the types chapter.
A compile-time invalid shift count is rejected; invalid runtime shift counts
are implementation-defined.

## <a id="compare_expressions"></a>Comparisons

### <a id="equality_expressions"></a>Equality

`==` and `!=` compare supported scalars, pointers, enums, structs
with supported equality, and compatible fixed arrays or slices. Slice equality
compares length and elements and does not allocate.

### <a id="identity_expressions"></a>Identity

`is` and `!is` compare representation identity. For pointers this
compares addresses; for slices it compares pointer and length. Laser-D has no
class or interface identity.

### <a id="array_comparisons"></a>Array and Slice Comparisons

Equality and identity are supported for compatible arrays and slices.
Ordered comparisons `<`, `<=`, `>`, and `>=` are rejected because
their D implementation requires a runtime comparison hook.

### <a id="struct_equality"></a>Struct Equality

Struct equality uses a supported `opEquals` overload when present;
otherwise it compares fields according to their supported equality semantics.

### <a id="class-comparisons"></a>Class Comparisons (Excluded)

> **Excluded from Laser-D:** Class and interface comparisons are unavailable.

## <a id="arithmetic_expressions"></a>Arithmetic

Supported numeric values provide unary sign, addition, subtraction, multiplication, division, remainder, and exponentiation under the conversions
defined by the types chapter. Integer overflow wraps to the destination width.
Integer division by zero and signed minimum divided by negative one are invalid;
when encountered at runtime their behavior is undefined.

### <a id="pointer_arithmetic"></a>Pointer Arithmetic

Adding or subtracting an integer from `T*` advances by multiples of
`T.sizeof`. Subtracting pointers into the same object yields `ptrdiff_t`.
Producing or dereferencing an invalid pointer is undefined.

### <a id="CatExpression"></a>Concatenation (Excluded)

> **Excluded from Laser-D:**
>
> Built-in array and string concatenation with `~` or
> `~=` is rejected because it requires allocation. The tokens remain in the
> grammar for modern operator overloading.

## <a id="cast_expressions"></a>Casts

`cast(T) expression` performs an explicit conversion to a supported
type `T`. It cannot cast to a rejected scalar family, class, interface, associative array, vector, or rejected qualifier.

### <a id="cast_pointers"></a>Pointer Casts

Pointer casts reinterpret an address and do not establish alignment, lifetime, bounds, or ownership.

### <a id="cast_array"></a>Array and Slice Casts

Array and slice casts are limited by the fixed-storage and non-owning-view
rules in the arrays chapter.

### <a id="cast_class"></a>Class Casts (Excluded)

> **Excluded from Laser-D:** Class casts and runtime checked casts are unavailable.

## <a id="postfix_expressions"></a>and Slicing

### <a id="argument-list"></a>Function Arguments

Functions, function pointers, delegates, constructors, templates, operator
calls, and UFCS calls require an explicit parenthesized argument list. Named
and positional arguments bind to parameters once; omitted parameters must have
a supported default argument.

#### <a id="argument-parameter-matching"></a>Argument Matching

Positional arguments bind in order. A named argument binds the parameter
with that name. A parameter cannot be bound twice. Every remaining parameter
must have a default.

### <a id="index_operations"></a>Indexing

Fixed arrays, slices, and pointers support one-dimensional indexing.
`$` is the current length where available. Struct operators may implement
one- and multidimensional indexing using the modern hooks.

### <a id="slice_operations"></a>Slicing

Slicing fixed arrays, slices, or explicit pointer ranges produces a
non-owning slice. Bounds and lifetime remain the programmer's responsibility.
Modern struct hooks may implement dimension-tagged slicing.

## <a id="primary_expressions"></a>Primary Expressions

```text
PrimaryExpression:
    Identifier
    . Identifier
    TemplateInstance
    . TemplateInstance
    $
    LiteralExpression
    FundamentalType . Identifier
    TypeCtor[] ( Type ) . Identifier
    FundamentalType ( NamedArgumentList[] )
    TypeCtor[] ( Type ) ( NamedArgumentList[] )
    Typeof
    IsExpression
    ( Expression )
    SpecialKeyword
    TraitsExpression

LiteralExpression:
    this
    null
    true_falsetrue
    false
    IntegerLiteral
    FloatLiteral
    CharacterLiteralcharacter-literalCharacterLiteral
    StringLiteral
    FunctionLiteral
```

> **Laser-D normative:**
>
> The primary-expression grammar is fully classified.
> Identifiers, root-qualified identifiers, template instances, `$` in an
> indexing context, literals of retained types, retained compiler properties, scalar construction, `typeof`, `is`, parentheses, the supported special
> keywords, and non-capturing function literals are available. Each form remains
> subject to its type and feature-specific restrictions.

> **Excluded from Laser-D:**
>
> Primary forms that allocate, require runtime type metadata, perform compile-time file I/O, inject source text, introduce a rejected type, or depend on classes are unavailable. This includes dynamic and associative
> array literals, `typeid`, import expressions, string mixin expressions, `new`, `super`, and literals or properties belonging to rejected scalar
> families.

### <a id="this"></a>`this`

> **Supported in Laser-D:**
>
> Inside a struct or union constructor or instance method, `this` denotes the current value. It may qualify field access, be passed or
> returned by value, have its address taken as a non-owning pointer, and form a
> delegate to a method. `typeof(this)` yields the receiver type without
> evaluating it. Template `this` parameters may infer a mutable or immutable
> receiver type.

A pointer or delegate derived from `this` does not own or extend the
receiver lifetime. Structs and unions have no inheritance or hidden virtual
table. Member aggregate types have no enclosing value instance, and local
structs that require a hidden outer context are rejected. Reference returns, closure capture, constructor delegation, and `alias this` remain governed
by their separate rejection rules.

### <a id="super"></a>`super` (Excluded)

> **Excluded from Laser-D:**
>
> `super` has no meaning because Laser-D structs do not
> inherit and native classes and interfaces are rejected.

### <a id="null"></a>`null`

`null` converts to a pointer, slice, function pointer, or delegate. It
does not represent a class or associative-array reference.

### <a id="StringLiteral"></a>String Literals

String literals are immutable, compiler-provided static storage viewed
through a non-owning character slice.

### <a id="function_literals"></a>Function Literals

```text
FunctionLiteral:
    function BasicTypeWithSuffixes[] Parameters[] FunctionLiteralBody
    delegate BasicTypeWithSuffixes[] Parameters[] FunctionLiteralBody
    Parameters FunctionLiteralBody
    Identifier => AssignExpression

BasicTypeWithSuffixes:
    BasicType TypeSuffixes[]

FunctionLiteralBody:
    => AssignExpression
    SpecifiedFunctionBody
```

Non-capturing function and delegate literals are supported, including
parameter and return-type inference. A literal that captures an enclosing local
variable is rejected. Function contracts, ref results, and `auto ref` are
also rejected.

#### <a id="lambda-type-inference"></a>Lambda Type Inference

Omitted parameter or result types are inferred at compile time. Inference
cannot produce an excluded type or attribute.

### <a id="is_expression"></a>`is` Expressions

```text
IsExpression:
    is ( Type )
    is ( Type : TypeSpecialization )
    is ( Type == TypeSpecialization )
    is ( Type Identifier )
    is ( Type Identifier : TypeSpecialization )
    is ( Type Identifier == TypeSpecialization )

TypeSpecialization:
    Type
    TypeCtor
    struct
    union
    enum
    function
    delegate
    return
    __parameters
    module
    package
```

`is` performs compile-time validity, equivalence, conversion, category, and pattern-deduction queries over the supported type system. Class, interface, vector, and `super` specializations are absent.

### <a id="specialkeywords"></a>Special Keywords

```text
SpecialKeyword:
    __FILE__
    __FILE_FULL_PATH__
    __MODULE__
    __LINE__
    __FUNCTION__
    __PRETTY_FUNCTION__
```

These keywords produce compile-time source-location and symbol strings or
the current source line. They allocate no runtime storage.

## <a id="excluded_primary"></a>Excluded Primary Expressions

### <a id="array_literals"></a>Array Literals (Excluded)

#### <a id="array-literal-heap"></a>Runtime Array Literal Allocation

> **Excluded from Laser-D:**
>
> Dynamic array literal expressions are rejected. Fixed-array
> and static-data initializers use declaration initializer syntax instead.

### <a id="associative_array_literals"></a>Associative Array Literals (Excluded)

#### <a id="AssocArrayLiteral"></a>Associative Array Literal Grammar

> **Excluded from Laser-D:** Associative-array types and literals are rejected.

### <a id="mixin_expressions"></a>String Mixin Expressions (Excluded)

> **Excluded from Laser-D:**
>
> Compile-time source-text injection with `mixin(expression)`
> is rejected. Template mixins are separate.

### <a id="import_expressions"></a>Compile-Time Import Expressions (Excluded)

> **Excluded from Laser-D:**
>
> `import("file")` is rejected because source-selected
> compile-time file I/O is disabled.

### <a id="new_expressions"></a>`new` Expressions (Excluded)

#### <a id="NewExpression"></a>New Expression Grammar

> **Excluded from Laser-D:** Every `new` form is rejected, including scalar, struct, array, placement, class, and allocator forms.

### <a id="typeid_expressions"></a>`typeid` Expressions (Excluded)

> **Excluded from Laser-D:**
>
> `typeid` is rejected because runtime `TypeInfo` is
> absent.

### <a id="RvalueExpression"></a>`__rvalue` Expression (Excluded)

> **Excluded from Laser-D:**
>
> `__rvalue(expression)` is rejected. Laser-D exposes no
> unchecked move or ownership hint.

### <a id="delete_expressions"></a>`delete` Expressions (Excluded)

> **Excluded from Laser-D:**
>
> `delete` is rejected with GC ownership and class
> destruction.

### <a id="throw_expression"></a>Throw Expressions (Excluded)

> **Excluded from Laser-D:** Throw expressions are rejected with D exception handling.

## <a id="expressions_under_review"></a>Expressions Under Review

### <a id="assert_expressions"></a>Assert Expressions

#### <a id="AssertExpression"></a>Assert Expression Grammar

> **Rejected in Laser-D:**
>
> Runtime `assert(condition)`, message forms, and
> `assert(0)` are rejected. Laser-D does not provide the druntime assertion
> failure hooks, and runtime checks do not disappear according to release or
> check-action compiler options. Programs use explicit conditions, return
> values, or C-compatible error reporting.

#### <a id="assert-ct"></a>Compile-Time Assertions

> **Supported in Laser-D:**
>
> `static assert(condition)` and
> `static assert(condition, message)` are supported. They are evaluated by
> the compiler and produce no runtime code. An ordinary runtime `assert`
> inside a CTFE-capable function remains rejected; CTFE does not change its
> source-language classification. ImportC retains C `_Static_assert`.

### <a id="interpolation_expressions"></a>Interpolation Expressions

> **Rejected in Laser-D:**
>
> Interpolation expression sequences are rejected in all lexical
> forms. Their string-like syntax lowers to a tuple-like sequence of sentinels, template metadata, and embedded values, automatically imports
> `core.interpolation`, and reparses stored expression text through an
> internal string mixin. Use ordinary string literals and explicit formatting or
> argument passing.
