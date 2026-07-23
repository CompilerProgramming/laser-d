---
title: Statements
status: restricted
source: ../spec/statement.dd
---

# Statements

Statements control execution within a function and have no value. Laser-D
supports blocks, expressions, declarations, returns, structured scalar control
flow, direct fixed-array/slice and numeric-range iteration, integral and enum
switches, explicit control transfers, imports, compile-time statements, and
`scope(exit)` cleanup.

## <a id="grammar"></a>Statement Grammar

```text
Statement:
    EmptyStatement
    NonEmptyStatement
    ScopeBlockStatement

EmptyStatement:
    ;

NoScopeNonEmptyStatement:
    NonEmptyStatement
    BlockStatement

NoScopeStatement:
    EmptyStatement
    NonEmptyStatement
    BlockStatement

NonEmptyOrScopeBlockStatement:
    NonEmptyStatement
    ScopeBlockStatement

NonEmptyStatement:
    ExpressionStatement
    DeclarationStatement
    ReturnStatement
    ScopeGuardStatement
    ImportDeclaration
    ConditionalStatement
    StaticForeachStatement
    LabeledStatement
    IfStatement
    WhileStatement
    DoStatement
    ForStatement
    ForeachStatement
    ForeachRangeStatement
    SwitchStatement
    FinalSwitchStatement
    CaseStatement
    CaseRangeStatement
    DefaultStatement
    ContinueStatement
    BreakStatement
    GotoStatement
    WithStatement

NonEmptyStatementNoCaseNoDefault:
    ExpressionStatement
    DeclarationStatement
    ReturnStatement
    ScopeGuardStatement
    ImportDeclaration
    ConditionalStatement
    StaticForeachStatement
    LabeledStatement
    IfStatement
    WhileStatement
    DoStatement
    ForStatement
    ForeachStatement
    ForeachRangeStatement
    SwitchStatement
    FinalSwitchStatement
    ContinueStatement
    BreakStatement
    GotoStatement
    WithStatement

ScopeStatement:
    NonEmptyStatement
    BlockStatement

ScopeBlockStatement:
    BlockStatement

BlockStatement:
    { }
    { StatementList }

StatementList:
    statement
    statement StatementList

ExpressionStatement:
    Expression ;

DeclarationStatement:
    StorageClasses[] Declaration

ReturnStatement:
    return ;
    return Expression ;

ScopeGuardStatement:
    scope ( exit ) NonEmptyOrScopeBlockStatement
```

Each statement alternative remains subject to its section below. Advanced
iteration protocols and conditional-compilation forms that are still under
review are not implied by the surrounding statement grammar.

## <a id="BlockStatement"></a>Blocks and Scope

> **Laser-D normative:**
>
> A block is a lexical sequence of statements enclosed by
> braces. Local names follow D lexical-scope rules. Leaving a block ends the
> lifetime of its automatic storage, but Laser-D runs no destructor or postblit
> hook implicitly.

## <a id="ExpressionStatement"></a>Expression Statements

An expression statement evaluates an expression for its side effects. An
expression with no effect is rejected unless explicitly converted to
`void`.

```d
int value;
++value;
cast(void)(value + 1);
```

## <a id="DeclarationStatement"></a>Declaration Statements

A declaration statement introduces a supported local variable, alias, type, function, template, import, or compile-time declaration. It remains
subject to the declarations chapter.

## <a id="ReturnStatement"></a>Return Statements

> **Laser-D normative:**
>
> `return;` exits a function with no result.
> `return expression;` converts the expression to the function's value result
> type and exits. Reference returns are unavailable.

Before control leaves, active `scope(exit)` guards execute in reverse
order of registration. No exception unwinding or module lifecycle action is
performed.

## <a id="ScopeGuardStatement"></a>Deterministic Cleanup

> **Laser-D normative:**
>
> `scope(exit)` is Laser-D's sole language-level cleanup
> syntax. Its statement executes exactly once when control leaves the enclosing
> lexical scope after the guard has been reached, including by fall-through, `return`, or another supported control transfer.

```d
extern(C) void release(int handle);

int use(int handle)
{
    scope(exit) release(handle);
    return handle;
}
```

Multiple guards in one scope execute in last-in, first-out order. A guard
body cannot transfer control out of itself. Cleanup must be explicit about any
failure state because Laser-D has no exception-success distinction.

> **Excluded from Laser-D:**
>
> `scope(success)` and `scope(failure)` are rejected.
> There is no exception state on which their distinction could depend.

## <a id="compile_time_statements"></a>Compile-Time Statements

`static if`, `static foreach`, and `static assert` are supported
as compile-time selection, iteration, and validation. Templates and CTFE remain
subject to every ordinary Laser-D restriction.

The shared upstream *ConditionalStatement* grammar also contains
`version` and `debug` forms. Those forms remain under review and are not
implied by support for `static if`.

## <a id="ordinary_control_flow"></a>Ordinary Control Flow

> **Laser-D normative:** Laser-D supports `if`, `while`, `do`, `for`, direct `foreach` and `foreach_reverse`, numeric range foreach, `switch`, `final switch`, `break`, `continue`, labels, `goto`, and `with` under the restrictions below.

### <a id="IfStatement"></a>If Statement

```text
IfStatement:
    if ( Expression ) ScopeStatement
    if ( Expression ) ScopeStatement else ScopeStatement

ThenStatement:
    ScopeStatement

ElseStatement:
    ScopeStatement
```

#### <a id="boolean-conditions"></a>Boolean Conditions

A condition accepts `bool` or a supported scalar value with the Boolean
conversion defined by the types chapter. Arrays, structs without an overload, and rejected reference types do not have an implicit truth value.

### <a id="WhileStatement"></a>While Statement

```text
WhileStatement:
    while ( Expression ) ScopeStatement
```

### <a id="DoStatement"></a>Do Statement

```text
DoStatement:
    do ScopeStatement while ( Expression ) ;
```

### <a id="ForStatement"></a>For Statement

```text
ForStatement:
    for ( NoScopeStatement Expression[] ; Expression[] ) ScopeStatement
```

### <a id="ForeachStatement"></a>Foreach Statement

#### <a id="foreach_over_arrays"></a>Foreach over Arrays and Slices

#### <a id="foreach_over_tuples"></a>Foreach over Compile-Time Sequences

#### <a id="foreach_over_associative_arrays"></a>Associative-Array Foreach (Excluded)

```text
AggregateForeach:
    Foreach ( ForeachTypeList ; ForeachAggregate )

ForeachStatement:
    AggregateForeach NoScopeNonEmptyStatement

Foreach:
    foreach
    foreach_reverse

ForeachTypeList:
    ForeachType
    ForeachType , ForeachTypeList

ForeachType:
    ForeachTypeAttributes[] BasicType Declarator
    ForeachTypeAttributes[] Identifier
    ForeachTypeAttributes[] alias Identifier

ForeachTypeAttributes:
    ForeachTypeAttribute
    ForeachTypeAttribute ForeachTypeAttributes

ForeachTypeAttribute:
    enum
    ref
    TypeCtor

ForeachAggregate:
    Expression

RangeForeach:
    Foreach ( ForeachType ; LwrExpression .. UprExpression )

LwrExpression:
    Expression

UprExpression:
    Expression

ForeachRangeStatement:
    RangeForeach scope statement
```

Associative-array iteration is excluded with associative arrays. Direct
array, slice, and numeric-range forms are supported. Both `static foreach`
and ordinary `foreach` over compile-time tuples and sequences are supported;
the frontend expands these forms without a runtime iteration protocol.

> **Laser-D normative:**
>
> A struct is a forward range when it provides parameterless
> instance methods `empty()` returning `bool`, `front()` returning a
> supported non-`ref` value, and `popFront()` returning `void`. A struct
> is a bidirectional range when it additionally provides `back()` returning a
> supported non-`ref` value and `popBack()` returning `void`. The
> frontend validates these signatures and lowers range iteration to calls on a
> private copy of the range value. These compiler-generated calls are the sole
> exception to the general requirement that user function calls include
> parentheses.

> **Rejected in Laser-D:**
>
> Iteration through `opApply`, `opApplyReverse`, or a
> delegate aggregate is not supported. These callback forms hide control flow
> behind the loop syntax and require a compiler-generated delegate. Programs must
> use a range, explicit loop, or explicit calls.

### <a id="SwitchStatement"></a>Switch Statements

#### <a id="FinalSwitchStatement"></a>Final Switch Statement

```text
SwitchStatement:
    switch ( Expression ) ScopeStatement

FinalSwitchStatement:
    final switch ( Expression ) ScopeStatement

CaseStatement:
    case ArgumentList : ScopeStatementList

CaseRangeStatement:
    case Expression : .. case Expression : ScopeStatementList

DefaultStatement:
    default : ScopeStatementList

ScopeStatementList:
    statement list

StatementListNoCaseNoDefault:
    StatementNoCaseNoDefault
    StatementNoCaseNoDefault StatementListNoCaseNoDefault

StatementNoCaseNoDefault:
    EmptyStatement
    NonEmptyStatementNoCaseNoDefault
    ScopeBlockStatement
```

Integral and enum switches are supported, including case ranges, `final switch`, `goto case`, and `goto default`. String and character
slice switches are rejected because they require the unavailable
`object.__switch` runtime hook.

### <a id="ContinueStatement"></a>Continue Statement

```text
ContinueStatement:
    continue ;
    continue Identifier ;
```

### <a id="BreakStatement"></a>Break Statement

```text
BreakStatement:
    break ;
    break Identifier ;
```

### <a id="LabeledStatement"></a>Labels and Goto

```text
LabeledStatement:
    Identifier :
    Identifier : statement

GotoStatement:
    goto Identifier ;
    goto default ;
    goto case ;
    goto case Expression ;
```

Labels, ordinary `goto`, labeled `break` and `continue`, and
switch-targeted goto forms are supported. A transfer leaving a lexical scope
executes its active `scope(exit)` guards.

### <a id="WithStatement"></a>With Statement

```text
WithStatement:
    with ( Expression ) ScopeStatement
```

`with` is supported for retained value types, enums, and namespaces. It
does not enable classes, interfaces, or implicit function calls.

## <a id="rejected_statements"></a>Rejected Statements

### <a id="TryStatement"></a>Exception Statements

#### <a id="TryStatement"></a>Try Statement Grammar

> **Excluded from Laser-D:**
>
> Source `try`, `catch`, `finally`, and `throw` are
> rejected. Errors must be represented and propagated explicitly through values
> or C APIs. Internal frontend nodes used to lower `scope(exit)` are not
> source-language features.

### <a id="SynchronizedStatement"></a>Synchronized Statements

> **Excluded from Laser-D:** `synchronized` is rejected. Explicit C threading, atomics, and locking APIs remain available.

### <a id="asm"></a>Inline Assembly

> **Excluded from Laser-D:**
>
> D and GCC-style inline assembly statements are rejected in
> Laser-D source. ImportC assembly remains a separate ImportC review.

### <a id="MixinStatement"></a>String Mixin Statements

> **Excluded from Laser-D:**
>
> String mixin statements are rejected. Template mixins are
> declaration constructs and remain separately supported.

### <a id="PragmaStatement"></a>Pragma Statements

> **Under review:**
>
> Pragmas remain under review except that compile-time
> `pragma(msg)` output is explicitly rejected.
