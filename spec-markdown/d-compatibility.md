# D compatibility notes

Laser-D, short for Lesser D, is a deliberately smaller D dialect. It uses D
syntax and introduces no incompatible syntax: a valid Laser-D source program is
also a D source program. The reverse is not true.

This chapter is for readers bringing D knowledge or D source to Laser-D. The
other specification chapters define Laser-D directly and do not repeatedly
describe absent D features.

## Execution model

Laser-D always uses the equivalent of D's `-betterC` compilation model. This is
not an optional mode and the command line cannot enable the D runtime.

Laser-D has:

- no D runtime or garbage collector;
- no implicit language allocation;
- no `TypeInfo`, `ModuleInfo`, runtime reflection, or module registry;
- no automatically executed module or thread lifecycle functions;
- no D exception runtime; and
- no D-generated program entry point.

An executable defines either `extern(C) int main()` or
`extern(C) int main(int, char**)`. Storage is automatic, inline, deeply
immutable static storage, caller-provided storage, or storage returned by an
explicit foreign API. Ownership and release are explicit.

## Types

The following D type families are absent:

- classes and interfaces, including D, COM, Objective-C, and C++ forms;
- associative arrays;
- vector types and compiler SIMD types;
- imaginary and complex floating-point types;
- `real`;
- `cent` and `ucent`;
- `inout` and `shared` qualified types; and
- Objective-C object and protocol types.

`const` remains an aliasable read-only view and `immutable` retains transitive
immutability. Postfix `const` member-function qualifiers are absent. `auto`
type inference remains available where the inferred type is a Laser-D type.

Fixed-size arrays are value storage. `T[]` is a non-owning pointer-and-length
slice, not a GC-managed container. The following D array facilities are absent:

- dynamic-array allocation and resizing;
- assigning to slice `.length`;
- `.capacity`, `.reserve`, `.dup`, and `.idup`;
- concatenation and append;
- array operations that allocate an implicit result; and
- associative-array types, literals, lookup, and mutation.

Array literals are available only where they initialize fixed storage without
allocation. String literals are immutable static storage and string slices are
non-owning views.

When a named enum uses another enum as its base, every member after the first
has an explicit initializer; Laser-D does not synthesize the next value by
applying arithmetic to the base enum. An opaque enum has layout from its base
type but no default initializer.

## Aggregates and object model

Laser-D structs and unions are value types. They have no hidden vtable, class
identity, inheritance, monitor, or runtime type descriptor.

Laser-D does not provide:

- native classes or interfaces;
- inheritance, virtual dispatch, `super`, or object downcasts;
- C++, COM, or Objective-C aggregate declarations;
- struct destructors or postblits;
- copy or move constructors;
- struct invariants;
- `alias this`;
- hidden-context nested structs;
- constructor delegation; or
- language-managed construction through `new`.

Direct field-initializing struct constructors remain available as a convenience
for small value types. Named and anonymous unions, integral bit fields, methods,
and modern operator hooks remain available.

## Functions

Every Laser-D function and function type is implicitly `nothrow`, `@nogc`, and
`@system`. Those attributes cannot be written explicitly. Laser-D does not
perform safety or purity inference, and functions remain conservatively
impure.

The following D function facilities are absent:

- explicit `nothrow`, `@nogc`, `@system`, `@safe`, and `@trusted`;
- `pure` and `@live`;
- reference return values;
- `lazy`, `scope`, `return`, `inout`, `auto ref`, and `final` parameter forms;
- capturing delegates and closures;
- named nested functions;
- D runtime variadic functions and typesafe runtime variadics;
- function contracts;
- user-defined `@property` functions;
- calls which omit parentheses; and
- generated or platform-specific D entry points such as D `main`, `WinMain`,
  `DllMain`, and compiler-generated `-main`.

Parameters may use `in`, `out`, or `ref`. C ABI variadic functions remain
available for C interoperability. Non-capturing function literals, function
pointers, non-capturing delegates, and delegates to struct methods remain
available.

## Declarations, attributes, and lifecycle

Laser-D source cannot declare mutable global, module-static, function-static,
or aggregate-static storage. Manifest constants and deeply immutable static
data remain available. ImportC retains C global declarations.

Laser-D does not provide:

- user-defined attributes;
- `__gshared`;
- `synchronized` declarations;
- `@disable`;
- `abstract`, `override`, or class-member `final`;
- module constructors or destructors;
- static constructors or destructors;
- shared static constructors or destructors;
- thread-local constructors or destructors; or
- language `unittest` blocks and the `-unittest` mode.

Tests are ordinary programs with explicit calls and an explicit C entry point.

## Expressions and generated source

The following D expressions are absent:

- every use of `new`;
- runtime `assert`;
- `typeid`;
- `super`;
- interpolated expression sequences;
- string mixins;
- import expressions used for compile-time file input;
- `.im`; and
- operations whose result requires implicit GC allocation.

`__rvalue` and its related return-on-stack inspection facility are also absent.
Compile-time evaluation remains available for compiler-known values, but it
cannot read source-selected files or emit user-selected `pragma(msg)` output.

Template mixins remain available because they inject declarations which were
parsed normally; they do not reparse text as source.

## Statements, errors, and threading

Laser-D has ordinary structured control flow, integral and enum switches,
fixed-array and slice iteration, numeric iteration, compile-time sequence
iteration, and validated value-type range iteration.

The following D statements and protocols are absent:

- `try`, `catch`, `finally`, and `throw`;
- `scope(success)` and `scope(failure)`;
- `synchronized`;
- string switches;
- callback iteration through `opApply` or `opApplyReverse`;
- delegate-aggregate iteration; and
- inline assembly statements.

`scope(exit)` is the single deterministic-cleanup syntax. Failures are
represented explicitly, normally with return values or foreign API conventions.

Laser-D has no language-level multithreading model. `shared`, `__gshared`, and
`synchronized` are absent. Programs may call C threading and atomic APIs
through explicit foreign interfaces.

## Operators and properties

Modern struct operator hooks remain available, including value-returning
multidimensional indexing and slicing. Legacy D1 operator hook names are
absent. Operator hooks cannot restore reference returns, allocation, or any
other absent feature.

Compiler-provided properties are available only where specified for Laser-D
types. GC-dependent array properties, class properties, `.im`, and
user-defined `@property` functions are absent.

## Templates, CTFE, and traits

Laser-D retains templates, template constraints, inference, specialization,
recursive instantiation, template mixins, CTFE, `static if`, `static foreach`,
and `static assert`. Instantiation never makes an otherwise absent language
feature valid.

Most read-only `__traits` inspection remains available for generic code.
Predicates may report that an operand is not a class, associative array, or
other absent kind; this does not introduce that kind into Laser-D.

The following traits are absent:

- `__traits(toType)`, because it generates a type from text;
- `__traits(getPointerBitmap)`, because there is no GC scanning contract;
- `__traits(getUnitTests)`, because there are no language unit-test blocks; and
- the return-on-stack facility associated with `__rvalue`.

There is no runtime reflection. Traits operate only on compiler-known
information.

## Interoperability differences

ImportC accepts reviewed C11 source and selected GNU-compatible C extensions.
ImportC input remains C; it does not acquire D language features merely because
it shares the frontend.

Laser-D supports C ABI declarations and C++ linkage for reviewed free-function
interoperability. It does not support:

- C++ structs, classes, interfaces, member functions, inheritance, or
  construction rules;
- COM classes or interfaces;
- Objective-C linkage, classes, protocols, methods, or message dispatch; or
- language declarations for platform object models.

Complex foreign libraries should expose a C-callable boundary. Their
implementation may use features which are not part of Laser-D.

## Platform-specific and compiler features

Laser-D currently targets x86-64 Windows, Linux, and macOS. The source language
does not provide:

- D-style or GCC-style inline assembly;
- `__vector` or compiler SIMD intrinsics;
- Objective-C target features; or
- predefined versions which advertise rejected inline-assembly, SIMD,
  Objective-C, exception, contract, or unit-test facilities.

Architecture-specific code and vectorized implementations may be compiled by a
foreign toolchain and linked through an explicit C ABI.

## Compatibility principle

The absence of a feature is intentional even when an upstream D compiler could
lower a particular example without the D runtime. Laser-D includes a feature
only when its semantics are robust, portable across the supported targets, and
defined for the whole accepted feature boundary rather than for isolated cases.

The compiler's acceptance and rejection tests are normative evidence for these
boundaries. A D feature is not part of Laser-D merely because it is accepted by
upstream D or happens to survive `-betterC`.
