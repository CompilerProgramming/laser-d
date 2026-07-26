---
title: Statements
status: restricted
source: ../spec/statement.dd
---

# Statements

Statements control execution within a function and have no value. This chapter
specifies the reviewed Laser-D statement forms. Differences from D are
summarized in [D compatibility notes](d-compatibility.md), while statement
forms awaiting review are listed in [Feature status](../FEATURE_STATUS.md).

## Statement forms

```text
Statement:
    ;
    Expression ;
    Declaration
    return ;
    return Expression ;
    BlockStatement
    ScopeExitStatement
    CompileTimeStatement
    IfStatement
    WhileStatement
    DoStatement
    ForStatement
    ForeachStatement
    SwitchStatement
    ContinueStatement
    BreakStatement
    LabeledStatement
    GotoStatement
    WithStatement

BlockStatement:
    { }
    { StatementList }
```

Each expression, declaration, type, and compile-time operation used by a
statement must itself be supported by Laser-D.

## Blocks and declarations

A block is a lexical sequence of statements enclosed by braces. Names declared
within the block follow lexical scope.

A declaration statement introduces a supported local declaration. Its syntax
and meaning are specified in [Declarations](declaration.md).

An expression followed by `;` is evaluated for its side effects. The empty
statement is a single `;`.

## Returning from a function

```text
ReturnStatement:
    return ;
    return Expression ;
```

`return;` exits a function whose return type is `void`. `return expression;`
converts the expression to the function's value-result type and exits the
function.

Before control leaves, active `scope(exit)` guards execute in reverse order of
registration.

## Deterministic cleanup

```text
ScopeExitStatement:
    scope ( exit ) Statement
```

A `scope(exit)` guard becomes active when execution reaches it. Its statement
executes exactly once when control leaves the enclosing lexical scope, whether
by fall-through, `return`, `break`, `continue`, or `goto`.

Multiple guards in one scope execute in last-in, first-out order. A guard body
cannot transfer control out of itself.

```d
extern(C) void release(int handle);

int use(int handle)
{
    scope(exit) release(handle);
    return handle;
}
```

## Compile-time statements

`static if`, `static foreach`, and `static assert` select, expand, or validate
code during compilation. Their conditions and bodies remain subject to all
ordinary Laser-D rules.

See [Templates](template.md) for compile-time selection and iteration.

## Conditional execution

```text
IfStatement:
    if ( Expression ) Statement
    if ( Expression ) Statement else Statement
    if ( Declaration = Expression ) Statement
    if ( Declaration = Expression ) Statement else Statement
```

The condition is converted to `bool`. Exactly one selected branch executes.

A declaration condition initializes a local variable once and converts its
resulting value to `bool`:

```d
if (auto handle = acquireHandle())
{
    useHandle(handle);
}
```

The declaration may use `auto` inference or an explicit supported type. The
declared name is visible only in the selected `then` statement. It is not
visible in an `else` statement or after the complete `if` statement. This form
is useful when obtaining or converting a value and testing its validity should
share one narrow scope.

Declaration conditions in `while`, `switch`, and `with` remain under separate
review.

## Loops

```text
WhileStatement:
    while ( Expression ) Statement

DoStatement:
    do Statement while ( Expression ) ;

ForStatement:
    for ( Initializer? ; Expression? ; Expression? ) Statement
```

A `while` loop tests its condition before each iteration. A `do` loop tests
after each iteration. A `for` loop performs its initializer once, tests its
optional condition before each iteration, and evaluates its optional increment
expression after the loop body.

## Direct iteration

```text
ForeachStatement:
    foreach ( ForeachVariables ; AggregateExpression ) Statement
    foreach_reverse ( ForeachVariables ; AggregateExpression ) Statement
    foreach ( ForeachVariable ; LowerExpression .. UpperExpression ) Statement
    foreach_reverse ( ForeachVariable ; LowerExpression .. UpperExpression ) Statement
```

`foreach` iterates forward and `foreach_reverse` iterates in reverse.
Laser-D supports:

- values and optional indices from fixed arrays and slices;
- mutation of mutable array or slice elements through a `ref` value;
- integral half-open ranges written `lower .. upper`;
- compile-time tuples and sequences; and
- validated value-type ranges.

Compile-time sequence iteration is expanded by the frontend and has no runtime
iteration protocol.

### Value-type ranges

A struct is a forward range when it provides these parameterless instance
methods:

```d
bool empty();
Element front();
void popFront();
```

`Element` must be a supported value type and `front()` returns it by value. A
struct is a bidirectional range when it additionally provides:

```d
Element back();
void popBack();
```

The frontend validates these signatures. Iteration operates on a private copy
of the range value and invokes the range methods directly.

## Switch statements

```text
SwitchStatement:
    switch ( Expression ) Statement
    final switch ( Expression ) Statement

CaseStatement:
    case Expression : StatementList
    case Expression : .. case Expression : StatementList
    default : StatementList
```

The controlling expression has an integral or enum type. Case values are
compile-time constants compatible with that type. A case range includes both
of its endpoints.

`final switch` over an enum requires every enum member to be handled and does
not use a `default` label.

## Break and continue

```text
ContinueStatement:
    continue ;
    continue Identifier ;

BreakStatement:
    break ;
    break Identifier ;
```

`continue` starts the next iteration of its target loop. `break` exits its
target loop or switch. An identifier selects an enclosing labeled statement.
Any active `scope(exit)` guard in a scope being left executes first.

## Labels and `goto`

```text
LabeledStatement:
    Identifier : Statement

GotoStatement:
    goto Identifier ;
    goto default ;
    goto case ;
    goto case Expression ;
```

An ordinary `goto` transfers control to a label in the same function.
Switch-targeted forms transfer to the selected `case` or `default`. Any active
`scope(exit)` guard in a scope being left executes before the transfer.

## Struct `with`

```text
WithStatement:
    with ( Expression ) Statement
```

When the expression has struct type, unqualified field and method names inside
the statement are resolved against that value.
