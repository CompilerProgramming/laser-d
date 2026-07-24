---
title: Conditional compilation
status: restricted
source: ../spec/version.dd
---

# Conditional compilation

Laser-D supports compile-time selection, repeated expansion, and validation
through `static if`, `static foreach`, and `static assert`.

Conditional-compilation facilities that still await review are listed in
[Feature status](../FEATURE_STATUS.md). Differences from D are summarized in
[D compatibility notes](d-compatibility.md).

## `static if`

```text
StaticIf:
    static if ( AssignExpression ) DeclarationOrStatement
    static if ( AssignExpression ) DeclarationOrStatement
        else DeclarationOrStatement
```

The condition must be evaluable at compile time and convertible to `bool`.
When it is true, the first branch is selected; otherwise the optional `else`
branch is selected.

`static if` may select declarations at module, template, struct, union, and
function scope. It may also select statements within a function.

```d
enum width = 32;

static if (width == 32)
    alias Integer = int;
else
    alias Integer = long;

static assert(is(Integer == int));
```

Conditions may use compiler-known values, template parameters, `is`,
`typeof`, supported traits, and CTFE.

## `static foreach`

```text
StaticForeachStatement:
    static foreach ( Iterator ; CompileTimeAggregate ) Statement
    static foreach ( Iterator ; LowerBound .. UpperBound ) Statement
```

`static foreach` evaluates its aggregate or bounds at compile time and expands
the body once for each element. The iterator denotes the corresponding
compile-time value in each expansion; it is not runtime storage.

```d
int sum()
{
    int result;
    static foreach (value; 0 .. 5)
        result += value;
    return result;
}

static assert(sum() == 10);
```

A compile-time tuple or sequence may provide the elements:

```d
template Values(Items...)
{
    alias Values = Items;
}

int sumValues()
{
    int result;
    static foreach (value; Values!(4, 5, 6))
        result += value;
    return result;
}

static assert(sumValues() == 15);
```

The body is ordinary Laser-D code after expansion.

## `static assert`

```text
StaticAssert:
    static assert ( AssignExpression ) ;
    static assert ( AssignExpression , AssignExpression ) ;
```

The first expression is evaluated at compile time and converted to `bool`.
Compilation continues when it is true and fails with a diagnostic when it is
false. The optional second expression supplies a compile-time diagnostic
message.

```d
enum square(int value) = value * value;

static assert(1 + 1 == 2);
static assert(square!6 == 36, "unexpected square");
```

`static assert` is evaluated wherever its declaration is selected, independent
of runtime control flow.
