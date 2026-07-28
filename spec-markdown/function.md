---
title: Functions
status: restricted
source: ../spec/function.dd
---

# Functions

Laser-D functions are explicitly called, runtime-free callable units. The
language supports free functions, struct and union methods, function pointers,
non-capturing function and delegate literals, delegates to aggregate methods,
function templates, and compile-time execution.

## Declarations

```text
FunctionDeclaration:
    ResultType Identifier Parameters FunctionBody
    auto Identifier Parameters FunctionBody

Parameters:
    ( )
    ( ParameterList )

ParameterList:
    Parameter
    Parameter , ParameterList

Parameter:
    Type Identifier
    Type Identifier = DefaultArgument
    in Type Identifier
    in Type Identifier = DefaultArgument
    out Type Identifier
    ref Type Identifier

FunctionBody:
    ;
    BlockStatement
```

A definition has a block body:

```d
int add(int left, int right)
{
    return left + right;
}
```

A declaration ending in `;` introduces a function whose definition is supplied
by a separately compiled module or foreign library:

```d
extern(C) int abs(int value);
```

The declaration and definition have compatible result types, parameter types,
parameter passing, linkage, and calling conventions.

## Fixed function model

Every function and function type is:

- `nothrow`;
- `@nogc`;
- `@system`; and
- conservatively impure.

These properties are part of the type even though they are not written in
source. They apply to free functions, methods, external declarations, function
pointers, delegates, literals, templates, inferred functions, and
compiler-generated helpers.

A function body uses ordinary Laser-D statements, expressions, local
declarations, and explicitly called foreign APIs.

## Parameters

A parameter without an annotation is passed by value:

```d
int doubled(int value)
{
    return value * 2;
}
```

The supported parameter annotations are `in`, `out`, and `ref`.

### `in`

An `in` parameter supplies an input value. The function does not use the
parameter to replace the caller's value:

```d
int square(in int value)
{
    return value * value;
}
```

The compiler may select an ABI-appropriate physical passing strategy without
changing the source-level input semantics.

### `ref`

A `ref` parameter aliases an initialized compatible caller lvalue:

```d
void increment(ref int value)
{
    ++value;
}
```

Changes made through the parameter affect the caller's object.

### `out`

An `out` parameter aliases compatible caller storage for an output value:

```d
void split(int value, out int quotient, out int remainder)
{
    quotient = value / 10;
    remainder = value % 10;
}
```

The parameter storage is initialized according to its type before the function
body uses it.

`ref` and `out` require lvalues. They allocate no storage and do not extend an
object's lifetime.

### Default arguments

A value parameter may have a compile-time-valid default expression:

```d
int scale(int value, int factor = 2)
{
    return value * factor;
}

int result()
{
    return scale(21);
}
```

The default is evaluated at the call site when the argument is omitted.
Parentheses remain part of the call.

## Return values

A function returns `void` or a supported value type.

```d
int answer()
{
    return 42;
}

void consume(int value)
{
    return;
}
```

A value-returning function uses `return expression;`. A `void` function uses
`return;` or reaches the end of its body where control flow permits.

Fixed arrays, structs, unions, enums, pointers, slices, function pointers, and
delegates are returned according to their value representation. Returning a
pointer, slice, or delegate does not transfer ownership or extend the lifetime
of referenced context or storage.

Source-written lifetime annotations are not part of Laser-D. The `return` and
`scope` keywords are rejected as parameter annotations and as postfix
member-function qualifiers.

For a method of a templated aggregate, the compiler may infer that a returned
pointer is derived from the receiver. A caller cannot return that pointer beyond
the lifetime of a shorter-lived receiver:

```d
struct Box(T)
{
    T value;

    T* pointer()
    {
        return &value;
    }
}

int* invalidEscape()
{
    Box!int box;
    return box.pointer(); // Error: the pointer escapes box.
}
```

This rule introduces no qualifier syntax. It is a narrow guarantee for inferred
templated receiver relationships, not general lifetime or ownership checking;
the same analysis is not guaranteed for a non-template aggregate method.

### Inferred result type

`auto` infers a value result type from reachable return expressions:

```d
auto difference(int left, int right)
{
    return left - right;
}

static assert(is(typeof(difference(4, 2)) == int));
```

All reachable value returns have a common compatible result type.

## Calls

A source-level call always uses parentheses:

```d
int callAnswer()
{
    return answer();
}
```

Arguments are evaluated and matched to parameters using overload resolution.
Each argument converts to its selected parameter type before the call.

Calling through a null function pointer or delegate is invalid.

## Overloading

Free functions and aggregate methods may share a name when their parameter
types or immutable receiver status allow one unique best candidate:

```d
int magnitude(int value)
{
    return value < 0 ? -value : value;
}

double magnitude(double value)
{
    return value < 0.0 ? -value : value;
}
```

The result type alone does not distinguish overloads. Imports, aliases, and
templates may contribute functions to an overload set. A call must have one
best applicable function.

## Local variables

Function-local variables have automatic storage unless they refer to storage
provided explicitly by a caller or foreign API:

```d
int calculate(int input)
{
    int temporary = input + 1;
    return temporary * 2;
}
```

A function may contain deeply immutable static data with a compile-time
initializer, as defined by the declarations chapter.

## Aggregate methods

A struct or union method uses the aggregate as its explicit context:

```d
struct Counter
{
    int value;

    void increment()
    {
        ++value;
    }

    int read()
    {
        return value;
    }
}
```

Method selection is static and direct. Methods add no per-object storage.

An immutable receiver method places `immutable` after its parameter list:

```d
struct Value
{
    int number;

    int read() immutable
    {
        return number;
    }
}
```

## Function pointers

A function pointer contains a code address and no context:

```d
alias BinaryOperation = int function(int, int);

int add(int left, int right)
{
    return left + right;
}

int invoke(BinaryOperation operation, int left, int right)
{
    return operation(left, right);
}
```

Taking a free function's address produces a compatible function pointer:

```d
int callThroughPointer()
{
    BinaryOperation operation = &add;
    return operation(20, 22);
}
```

A non-capturing function literal may also initialize a function pointer:

```d
int callLiteral()
{
    int function(int) increment =
        function int(int value) { return value + 1; };
    return increment(41);
}
```

Function-pointer assignment and argument passing require compatible function
types.

## Delegates

A delegate contains a context pointer and a function pointer.

A non-capturing delegate literal has no lexical state:

```d
int callDelegateLiteral()
{
    int delegate(int) twice = (int value) => value * 2;
    return twice(21);
}
```

A delegate to a struct method uses the addressed struct object as its context:

```d
struct Offset
{
    int amount;

    int add(int value)
    {
        return amount + value;
    }
}

int invokeMethod(ref Offset offset)
{
    int delegate(int) operation = &offset.add;
    return operation(2);
}
```

The delegate does not own or extend the lifetime of its context.

Delegate `.ptr` and `.funcptr` expose the two represented pointers as described
by the properties chapter.

## Function and delegate literals

Function syntax and lambda syntax create anonymous callable values:

```d
int callLiterals()
{
    int function(int) increment =
        function int(int value) { return value + 1; };

    int delegate(int) doubled = (int value) => value * 2;
    return increment(20) + doubled(10);
}
```

Their parameters, result types, bodies, and implicit function properties follow
the same rules as named functions. Laser-D delegate literals have no captured
lexical variables.

## C variadic functions

An `extern(C)` function may end its parameter list with `...`:

```d
extern(C) int firstArgument(int first, ...);
alias CVariadicFunction = extern(C) int function(int first, ...);
```

C variadic functions may be declared, defined, called, and used through
function pointers. They have at least one named parameter and use the target C
ABI.

A definition makes the target `va_list` declarations visible where required,
normally by importing `core.stdc.stdarg`.

Variadic template parameters are a separate compile-time template feature.

## Function templates

A function template may infer template arguments from a call:

```d
T maximum(T)(T left, T right)
{
    return left > right ? left : right;
}

static assert(maximum(3, 4) == 4);
```

Explicit arguments, inference, specialization, defaults, and constraints follow
the templates chapter. Every instantiated function follows this function
model.

## Compile-time execution

A supported function may execute during compile-time function evaluation:

```d
int square(int value)
{
    return value * value;
}

enum sixteen = square(4);
```

Compile-time execution uses the same function body and language semantics as
runtime execution.

## Uniform function call syntax

Uniform function call syntax (UFCS) rewrites a method-shaped call to an
ordinary free-function call when the expression before the dot matches the
first parameter:

```d
int twice(int value)
{
    return value * 2;
}

int calculate()
{
    return 3.twice();
}
```

The call uses parentheses and ordinary overload resolution.

## Program entry point

An executable defines exactly one of:

```d
extern(C) int main();
extern(C) int main(int argc, char** argv);
```

The definition uses the target C runtime ABI and returns an integer status:

```d
extern(C) int main()
{
    return 0;
}
```

A library does not define an entry point. ImportC translation units retain
their C entry-point handling.

Compiler-generated helpers required to implement another supported construct
are implementation details and do not add source-level entry-point forms.
