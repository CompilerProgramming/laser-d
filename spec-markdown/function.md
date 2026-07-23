---
title: Functions
status: restricted
source: ../spec/function.dd
---

# Functions

Laser-D supports ordinary functions, struct methods, function pointers, non-capturing function and delegate literals, non-capturing delegates, and
delegates to struct methods. Functions use an explicit, runtime-free calling
model and remain subject to every Laser-D type and storage restriction.

## <a id="grammar"></a>Function Declarations

```text
FunctionDeclaration:
    Type Identifier Parameters FunctionBody
    auto Identifier Parameters FunctionBody

Parameters:
    ( )
    ( ParameterList )

ParameterList:
    Parameter
    Parameter , ParameterList

Parameter:
    ParameterStorageClass[] Type Identifier[]
    ParameterStorageClass[] Type Identifier[] = AssignExpression

ParameterStorageClass:
    in
    out
    ref

FunctionBody:
    ;
    BlockStatement
```

### Function Parameters

Parameters are evaluated and matched from left to right according to the
ordinary call and overload rules. A parameter with no storage-class annotation
is passed by value. The only permitted source annotations are `in`, `out`, and `ref`.

> **Rejected in Laser-D:**
>
> Parameter annotations `scope`, `lazy`, `return`, `inout`, and `shared`, together with combinations derived from them, are
> rejected. User-defined parameter attributes are also rejected.

### <a id="attributes"></a>Function Model and Attributes

> **Laser-D normative:**
>
> Every Laser-D function and function type is implicitly
> `nothrow`, `@nogc`, and `@system`. These properties apply to ordinary
> functions, external declarations, methods, pointers, delegates, literals, templates, inferred functions, and frontend-generated helpers.

The implicit attributes are language invariants and are not written in
source. Attribute inference cannot weaken or strengthen them.

> **Rejected in Laser-D:**
>
> Explicit `nothrow`, `@nogc`, `@system`, `@safe`, `@trusted`, `pure`, `@live`, `@property`, and `@disable` are
> rejected. Function contracts and user-defined attributes are rejected
> separately below.

A struct method may use an `immutable` receiver. The rejected `const`, `inout`, and `shared` receiver qualifiers are unavailable.

### <a id="function-bodies"></a>Function Bodies

A function definition has a normal block body. Its statements and local
declarations must use supported Laser-D constructs.

> **Rejected in Laser-D:** Contract-style `do` bodies, expression and block contracts, and body syntax belonging to rejected function facilities are not supported.

### <a id="function-declarations"></a>Function Prototypes

A declaration ending in `;` introduces a function without defining its
body. This is used for separate compilation and C or supported C++ free-function
interoperability. The declaration's type must match its definition and ABI.

## <a id="contracts"></a>Function Contracts

### <a id="preconditions"></a>Preconditions

> **Rejected in Laser-D:**
>
> Function `in` contract blocks and expressions are rejected.
> The parameter annotation `in` is a distinct, supported parameter feature.

### <a id="postconditions"></a>Postconditions

> **Rejected in Laser-D:**
>
> Function `out` contract blocks, result identifiers, and
> contract-style `do` bodies are rejected. The parameter annotation `out`
> is a distinct, supported parameter feature.

Preconditions and postconditions may be expressed as ordinary explicitly
called functions when desired.

## <a id="function-return-values"></a>Function Return Values

A function may return `void` or a supported value type. A value-returning
function uses `return expression;`; a void function uses `return;` or
reaches the end of its body where permitted.

Returning fixed arrays, structs, unions, enums, pointers, non-owning slices, function pointers, and delegates follows their respective value and lifetime
rules. A returned slice or pointer does not acquire ownership or an extended
lifetime.

> **Rejected in Laser-D:**
>
> Source-level `ref` return values are rejected, including
> `auto ref`, explicit constructor return annotations, and reference-returning
> operator hooks. Return annotations on parameters are also rejected.

## <a id="pure-functions"></a>Purity

> **Rejected in Laser-D:**
>
> Laser-D does not expose D's explicit or inferred `pure`
> function property. Functions remain conservatively impure so calls to C and
> explicitly managed state require no qualifier escape.

### <a id="weak-purity"></a>Purity Categories

D's weak/strong purity distinction is not part of Laser-D.

### <a id="pure-special-cases"></a>Purity Special Cases

No special pure-function conversions or optimizations form part of the
Laser-D language contract.

#### <a id="pure-debug"></a>Debugging Pure Functions

This upstream facility is unavailable because `pure` is rejected.

### <a id="pure-nested"></a>Pure Nested Functions

This upstream facility is unavailable because `pure` is rejected.

### <a id="pure-factory-functions"></a>Pure Factory Functions

This upstream facility is unavailable because `pure` and implicit
allocation are rejected.

### <a id="pure-optimization"></a>Purity Optimizations

Backend optimizations do not create source-visible purity guarantees.

## <a id="nothrow-functions"></a>Non-Throwing Functions

Every function is implicitly non-throwing because D exceptions and
`throw` are rejected. The `nothrow` keyword cannot be written explicitly.

## <a id="ref-functions"></a>Reference-Returning Functions

> **Rejected in Laser-D:**
>
> Reference-returning functions are rejected. Functions return
> values, pointers, or non-owning slices when caller-visible access is required.

## <a id="auto-functions"></a>Inferred Return Types

A function declared with `auto` may infer its value return type from all
reachable return expressions. Every inferred type must be supported and the
returns must have a common compatible type.

## <a id="auto-ref-functions"></a>Inferred Reference Returns

> **Rejected in Laser-D:**
>
> `auto ref` and every inferred or explicit reference return
> are rejected.

## <a id="inout-functions"></a>Inout Functions

> **Rejected in Laser-D:**
>
> `inout` functions, receivers, parameters, returns, and
> wildcard qualifier matching are rejected.

## <a id="optional-parenthesis"></a>Optional Parentheses

> **Rejected in Laser-D:**
>
> Function and method calls always require explicit
> parentheses, including zero-argument functions and functions whose parameters
> all have default arguments.

## <a id="property-functions"></a>Property Functions

> **Rejected in Laser-D:**
>
> User-defined `@property` functions and property-style
> getter/setter calls are rejected. Executable source-defined behavior must look
> like an explicit call.

## <a id="virtual-functions"></a>Virtual Functions

> **Rejected in Laser-D:**
>
> Virtual functions are unavailable because classes and
> interfaces are rejected. Struct methods use static dispatch and have no hidden
> virtual-function table.

### <a id="final"></a>Final Functions

Class/interface `final` semantics are unavailable. Any remaining
declaration use of `final` is governed by the attribute review and is not
implied by support for ordinary functions.

### <a id="covariance"></a>Covariant Returns

Class and interface return covariance is unavailable with those object
models.

### <a id="base-methods"></a>Base Methods

There are no base methods or `super` calls in Laser-D.

### <a id="function-inheritance"></a>Inherited Overloads

Function inheritance and overriding are unavailable. Free-function and
struct-method overload sets remain ordinary static overloads.

### <a id="override-defaults"></a>Overridden Default Arguments

Overriding is unavailable. Defaults on ordinary overloads are resolved at
the selected declaration.

### <a id="inheriting-attributes"></a>Inherited Attributes

There is no class/interface attribute inheritance.

### <a id="override-restrictions"></a>Override Restrictions

Override-specific restrictions are unavailable because overriding is
unavailable.

## <a id="inline-functions"></a>Inlining

Inlining is a compiler optimization and does not change Laser-D semantics.
Source controls for forcing or preventing inlining remain governed by the
pragma and attribute reviews.

## <a id="function-overloading"></a>Function Overloading

Free functions and struct methods may share a name when their parameter
types or supported qualifiers allow overload resolution to select one unique
candidate. Return type alone does not distinguish overloads.

### <a id="overload-sets"></a>Overload Sets

Imports, aliases, templates, and local declarations form overload sets under
their respective scope rules. A call that has no unique best supported match is
rejected.

## <a id="parameters"></a>Function Parameters

### <a id="param-storage"></a>Parameter Storage Classes

The only parameter storage-class annotations are `in`, `out`, and
`ref`. An omitted annotation passes a normal value.

### <a id="in-params"></a>`in` Parameters

An `in` parameter is an input parameter. It cannot be used to return a
replacement value to the caller. Its exact ABI passing strategy is selected by
the compiler without changing source semantics.

### <a id="ref-params"></a>`ref` and `out` Parameters

A `ref` parameter aliases an initialized caller lvalue. An `out`
parameter aliases caller storage for an output value and initializes that
storage according to the parameter rules before the function body uses it.

Both forms require a compatible caller lvalue and do not allocate or extend
its lifetime.

### <a id="lazy-params"></a>Lazy Parameters

> **Rejected in Laser-D:**
>
> `lazy` parameters are rejected. They introduce implicit
> deferred calls and delegate machinery.

### <a id="function-default-args"></a>Default Arguments

A parameter may have a compile-time-valid default expression. The expression
is evaluated at the call site when that argument is omitted. The call must
still include parentheses.

### <a id="return-ref-parameters"></a>Return-Ref Parameters

> **Rejected in Laser-D:**
>
> `return`, `return ref`, and equivalent parameter
> annotations are rejected.

#### <a id="struct-return-methods"></a>Struct Return Methods

Struct methods may return supported values, pointers, or slices but not
references.

### <a id="scope-parameters"></a>Scope Parameters

> **Rejected in Laser-D:**
>
> Explicit and inferred source `scope` parameters are not part
> of Laser-D's function interface.

### <a id="return-scope-parameters"></a>Return-Scope Parameters

> **Rejected in Laser-D:** `return scope` parameters are rejected.

### <a id="ref-return-scope-parameters"></a>Ref Return-Scope Parameters

> **Rejected in Laser-D:**
>
> Combined `ref`, `return`, and `scope` lifetime
> annotations are rejected.

### <a id="pure-scope-inference"></a>Scope Inference

Laser-D does not expose purity-based or safety-based scope inference as a
source function property.

### <a id="udas-parameters"></a>Parameter Attributes

> **Rejected in Laser-D:** User-defined attributes on parameters are rejected.

### <a id="variadic"></a>Variadic Functions

Laser-D supports C ABI variadic functions solely for C interoperability.
D runtime variadic forms are rejected. Variadic template parameters are a
separate supported compile-time feature.

#### <a id="c_style_variadic_functions"></a>C-Style Variadic Functions

> **Supported in Laser-D:**
>
> A function type declared with `extern(C)` may end its
> parameter list with `...`. Such functions may be declared, defined, called, and used through function pointers. Their arguments and return values use the
> target C ABI. At least one named parameter is required. A definition must have
> the target's `va_list` ABI declarations visible where the ABI requires them;
> the usual source is `core.stdc.stdarg`.

#### <a id="d_style_variadic_functions"></a>D-Style Variadic Functions

> **Rejected in Laser-D:**
>
> D-style untyped variadic functions are rejected. Laser-D does
> not provide the hidden TypeInfo argument list used by that calling convention.

#### <a id="typesafe_variadic_functions"></a>Typesafe Variadic Functions

> **Rejected in Laser-D:**
>
> Typesafe runtime variadic parameters are rejected. Callers
> must pass an explicit supported aggregate or use variadic template parameters
> when compile-time expansion is intended.

#### <a id="lazy_variadic_functions"></a>Lazy Variadic Functions

> **Rejected in Laser-D:**
>
> Lazy variadic parameters are rejected by both the lazy
> parameter and runtime variadic restrictions. Laser-D does not create implicit
> delegates for variadic arguments.

### <a id="hidden-parameters"></a>Hidden Parameters

Struct methods receive their object context, and delegates contain an
explicit context pointer as part of the delegate value. Laser-D rejects class
context, closure capture, hidden-context nested structs, and hidden lifetime or
TypeInfo parameter protocols.

## <a id="refscopereturn"></a>Ref/Scope/Return Classification

### <a id="rsr_definitions"></a>Definitions

### <a id="rsr_classification"></a>Classification

### <a id="rsr_mapping"></a>Syntax Mapping

### <a id="rsr_memberfunctions"></a>Member Functions

### <a id="rsr_PandRef"></a>Pointer and Reference Cases

### <a id="rsr_covariance"></a>Variance

> **Rejected in Laser-D:**
>
> D's ref/scope/return lifetime-classification system is not a
> Laser-D source feature. The anchors above are retained for links from excluded
> upstream chapters.

## <a id="Local Variables"></a>Local Variables

Function-local variables use automatic storage unless explicitly provided
through supported external/manual storage. Their initialization and cleanup use
the ordinary declaration and statement rules.

### <a id="Local Static Variables"></a>Local Static Variables

> **Rejected in Laser-D:**
>
> Mutable function-static storage is rejected. Eligible deeply
> immutable static values remain governed by the declaration and qualifier
> chapters.

## <a id="nested"></a>Named Nested Functions

> **Rejected in Laser-D:**
>
> Named functions declared inside another function are rejected, including capturing, context-free, and `static` forms. Use a module-level
> helper or a non-capturing function literal.

### <a id="nested-qualifiers"></a>Nested Function Qualifiers

Nested functions cannot restore rejected qualifiers or attributes.

### <a id="nested-declaration-order"></a>Nested Declaration Order

Nested-function declaration order is unavailable because named nested
functions are rejected.

## <a id="function-pointers-delegates"></a>Function Pointers and Delegates

### <a id="function-pointers"></a>Function Pointers

A function pointer stores a callable code address with a compatible
function type. Taking the address of a free function, assigning a non-capturing
function literal, passing the pointer, and calling it with explicit parentheses
are supported.

### <a id="closures"></a>Delegates and Closures

A delegate stores a context pointer and function pointer. Non-capturing
delegate literals are supported and have no captured lexical state.

> **Rejected in Laser-D:**
>
> A function or delegate literal that captures a local variable
> is rejected. Named nested functions are rejected separately. Laser-D does not
> allocate or preserve closure frames.

### <a id="method-delegates"></a>Method Delegates

A delegate to a struct method is supported. Its context explicitly identifies
the struct value on which the method operates; this is not lexical closure
capture.

### <a id="function-pointer-attributes"></a>Function-Type Attributes

Function pointer and delegate types carry the same implicit `nothrow`, `@nogc`, and `@system` invariants as declarations. Explicit spellings and
rejected attributes are diagnosed.

### <a id="function-delegate-init"></a>Pointer and Delegate Initialization

Null initialization, compatible assignment, address-taking, and supported
explicit conversions follow the normal type rules. A null pointer or delegate
cannot be called validly.

### <a id="anonymous"></a>Function and Delegate Literals

Non-capturing function literals, lambdas, and delegate literals are
supported. Their parameter, return, body, and attribute surface is the same
restricted Laser-D function surface.

## <a id="main"></a>Program Entry Point

> **Supported in Laser-D:**
>
> An executable Laser-D program shall define exactly one of:
>
>
>
> ```d
> extern(C) int main();
> extern(C) int main(int argc, char argv);
> ```
>
>
>
> The entry point is explicit and uses the target C runtime ABI. A library need
> not define an entry point.

> **Rejected in Laser-D:**
>
> D-linkage `main`, `string[]` arguments, inferred, `void`, or `noreturn` return types, other parameter lists, the POSIX
> third environment-pointer parameter, and the special `WinMain` and
> `DllMain` entry points are rejected. The `-main` compiler option is
> rejected because it would silently generate an entry point.

ImportC source retains C entry-point rules. Frontend-generated function
helpers needed by otherwise supported constructs are implementation details, not additional source-level entry points.

## <a id="function-templates"></a>Function Templates

Function templates, inference, specialization, and constraints are
supported by the template chapter. Every instantiated function must obey this
chapter.

## <a id="interpretation"></a>Compile-Time Function Execution

Supported functions may execute during CTFE. CTFE does not relax any
Laser-D restriction and cannot perform compile-time file I/O or output.

### <a id="string-mixins"></a>CTFE and String Mixins

> **Rejected in Laser-D:**
>
> CTFE may compute strings as values but cannot reparse them as
> source through a string mixin.

## <a id="nogc-functions"></a>No-GC Functions

Every function is implicitly `@nogc`. The attribute cannot be written, and no function may use an operation requiring GC allocation.

## <a id="function-safety"></a>Function Safety

Every function is implicitly `@system`. Laser-D does not provide D's
checked memory-safety subset or trusted boundary.

### <a id="safe-functions"></a>Safe Functions

> **Rejected in Laser-D:** Explicit or inferred `@safe` functions are rejected.

#### Safe External Functions

External functions remain implicitly `@system`.

### <a id="trusted-functions"></a>Trusted Functions

> **Rejected in Laser-D:** `@trusted` functions are rejected.

### <a id="system-functions"></a>System Functions

All functions are implicitly system functions; explicit `@system` is
rejected because it is redundant.

### <a id="safe-interfaces"></a>Safe Interfaces

Interfaces and safe-interface rules are unavailable.

### <a id="safe-values"></a>Safe Values

No value acquires D safety guarantees from a function annotation.

### <a id="null-dereferences"></a>Null Dereferences

Calling through a null function pointer/delegate or dereferencing a null
pointer is invalid. Implicit `@system` does not insert a safety proof.

### <a id="safe-aliasing"></a>Safety Aliasing Rules

D's `@safe` aliasing restrictions are not Laser-D guarantees.

## <a id="function-attribute-inference"></a>Function Attribute Inference

Return type inference with `auto` is supported. Safety, purity, GC, and
throwing attributes are not inferred: the Laser-D function invariants are fixed
for every function type.

## <a id="pseudo-member"></a>Uniform Function Call Syntax (UFCS)

UFCS is supported for an ordinary free function whose first parameter
matches the expression before the dot. The call must use explicit parentheses, and UFCS does not create property behavior.

```d
int twice(int value)
{
    return value * 2;
}

int result = 3.twice();
```

## <a id="conformance"></a>Conformance Boundary

The established function subset includes ordinary declarations and bodies, prototypes, value returns and inference, explicit calls, static overloads, `in`/`out`/`ref` parameters, default arguments, local automatic
variables, function pointers, non-capturing literals and delegates, struct
method delegates, UFCS, function templates, and CTFE. Rejected attributes, contracts, reference returns, lifetime annotations, lazy parameters, closure
capture, virtual dispatch, property calls, and optional parentheses are outside
the language. Named nested functions and D runtime variadics are rejected; C
ABI variadics are supported. Executables use one of the two explicit C
`main` signatures specified above.
