# Laser-D design

The working inventory and review status of individual language features is in
[`FEATURE_STATUS.md`](FEATURE_STATUS.md). Language decisions recorded there
must remain consistent with this design, the normative Markdown specification
under `spec-markdown/`, and the tests under `compiler/test/laser-d`.

## Mandatory BetterC mode

Laser-D always compiles D source in BetterC mode. The compiler parameter
defaults disable ModuleInfo, TypeInfo, exception handling, and garbage
collector-dependent features. After configuration files and command-line
arguments are parsed, the driver reapplies the complete BetterC parameter set
so user input cannot disable or partially override it.

The `-betterC` option remains accepted for source-build compatibility with D
tooling, but it is redundant in Laser-D.

BetterC also enables the frontend's `allInst` parameter. Laser-D retains this
behavior so template instances needed by a root module are emitted into its
object files instead of relying on another object file or the D runtime to
provide them. This maximizes linkability for standalone programs and libraries
that have only the C runtime available. `allInst` does not impose the BetterC
language restrictions itself; it is a complementary template code-generation
setting used by upstream DMD whenever `-betterC` is selected.

`compiler/test/laser-d/betterc_default.d` and `betterc_mandatory.d` verify the
mandatory language mode. `betterc_template_emission.d` separately compiles,
links, and runs a template instance that must be emitted without relying on
the D runtime.

Regression tests for this behavior live in `compiler/test/laser-d` rather than
the upstream D test categories, because the upstream suite assumes full D
language and runtime support. Run the dedicated suite from `compiler/test`
with `./run.d laser-d`. Each Laser-D test declares whether it is compilable,
fail-compilation, or runnable using its `TEST_MODE` directive.

## Implicit function attributes

Function parameters may use only the `in`, `out`, and `ref` parameter storage
annotations. Laser-D rejects `scope`, `lazy`, `return`, `auto ref`, and `final`
parameter annotations. Functions and function literals cannot return by `ref`;
return values are ordinary values, and an explicitly `ref`-annotated
constructor is rejected. The frontend's internal in-place constructor return
does not constitute a source annotation. Postfix `return` and `scope`
member-function qualifiers are also rejected. This removes source-written
lifetime annotations, lazy thunks, inferred reference passing, and
reference-return aliasing from function boundaries.

The frontend nevertheless retains its internal receiver-lifetime inference for
templated aggregate methods. When such a method returns a pointer derived from
its receiver, the inferred relationship prevents that pointer from escaping a
shorter-lived receiver. This requires no Laser-D syntax and is intentionally a
narrow diagnostic guarantee: equivalent non-template methods are not promised
the same analysis, and Laser-D does not otherwise provide borrow checking.
`receiver_lifetime_qualifiers_rejected.d` fixes the source surface, while
`receiver_lifetime_inference.d` proves the retained escape diagnostic.

Every function type in Laser-D is implicitly `nothrow`, `@nogc`, and `@system`.
These are language invariants rather than optional annotations: they apply to
function declarations, function pointers, delegates, lambdas, inferred
functions, and functions synthesized by the frontend. Safety inference is
disabled, so no function becomes `@safe` based on its implementation.

Functions are also conservatively impure. Laser-D rejects the explicit `pure`
attribute and does not infer purity for D functions. This keeps C interoperation
sound. ImportC retains upstream handling of C purity-related attributes.

Writing either `nothrow` or `@nogc` explicitly is an error because source code
cannot opt into or out of these invariants. Calls and function-type conversions
therefore always expose the fixed attributes to the type system.

The `@safe` and `@trusted` subsets are not part of Laser-D. Explicit `@safe`,
`@trusted`, and `@system` are all rejected: the first two conflict with the
fixed safety model, while spelling `@system` is redundant. Laser-D therefore
provides no general compiler-checked memory-safety boundary. Apart from the
narrow templated receiver-lifetime inference described above, memory
correctness remains the program's responsibility.

The experimental `@live` ownership and borrowing analysis is also rejected.
`@live` cannot be attached to a declaration or function type, and no valid
Laser-D function type carries the live-analysis attribute.

`compiler/test/laser-d/implicit_function_attributes.d` covers declarations,
external functions, pointers, delegates, inferred return types, member
functions, and lambdas. The explicit-attribute tests verify rejection on
declarations, function pointers, and delegate types.

## Lexical analysis

Laser-D retains D lexical analysis unchanged. This includes the source
character set, whitespace, comments, identifiers, tokens, literal forms,
escape sequences, keywords, and special tokens. Laser-D restrictions are
applied during parsing or semantic analysis after tokenization; they do not
introduce a separate lexical dialect.

The focused tests in `compiler/test/laser-d/lexical_*.d` cover accepted forms
and representative malformed constructs. The upstream lexer diagnostic tests
were also compared between upstream DMD in BetterC mode and Laser-D; the
rejection results matched for the reviewed cases.

## Deterministic cleanup and error handling

Laser-D supports `scope(exit)` as its single source-language cleanup construct.
Source `try`, `catch`, `finally`, `throw`, `scope(success)`, and
`scope(failure)` are rejected. The frontend may still create internal
try/finally nodes when lowering `scope(exit)`; this is implementation machinery,
not an additional source feature. Laser-D programs report and propagate errors
explicitly, for example with return values or C APIs, rather than D exceptions.

D exceptions are not merely discouraged in Laser-D; they are unreachable. The D
exception hierarchy is rooted in `Throwable`, which is a class, and classes are
not part of Laser-D. Removing the class object model therefore removes the
exception model with it, and no source-level construct can reintroduce either.

The standard library supplies `laserd.result` as one supported convention for
returning failure as data. `Optional` carries a value which may be absent, and
`Result` carries either a value or an error; a `void` value type covers
operations which produce no value on success. Both are plain value types with no
allocation, runtime metadata, or hidden control flow. `Result` overlaps its
value and error storage, which is sound precisely because Laser-D rejects
destructors, postblits, and copy or move constructors, so no union member
carries lifecycle behaviour.

Every accessor in that module is total. Laser-D cannot compel a caller to
inspect a result: `@disable` is rejected, so construction cannot be routed
through a checked path, and destructors are rejected, so an unexamined value
cannot be detected when it leaves scope. A checked-access design would therefore
have to trap misuse at run time. Although mandatory runtime assertions are
available, this general-purpose result convention does not abort on an
unchecked accessor. The module instead guarantees that no accessor is
undefined on the absent side,
supplying a documented fallback or a null pointer. Transformations take ordinary
function pointers, with context passed explicitly, because capturing delegates
are rejected.

This module is a library convention rather than a language-mandated result
type. An API may still use status values, output parameters, or its own result
aggregate where those suit its domain or its foreign interface better.

## Ordinary control flow

Laser-D supports structured scalar control flow with `if`/`else`, `while`,
`do`/`while`, and `for`. It supports `break`, `continue`, labels, `goto`,
labeled transfers, and `goto case`/`goto default`. An active `scope(exit)`
guard runs when any of these transfers leave its lexical scope.

Direct `foreach` and `foreach_reverse` iteration over fixed arrays and
non-owning slices is supported, including index/value and `ref` value forms.
Numeric range foreach is also supported. Both `static foreach` and ordinary
`foreach` over compile-time tuples and sequences are supported; the frontend
expands them without a runtime iteration protocol.

Value-type ranges are supported through a deliberately small structural
protocol. Forward iteration requires parameterless instance methods `empty()`
returning `bool`, `front()` returning a non-`ref` supported value, and
`popFront()` returning `void`. Reverse iteration substitutes `back()` and
`popBack()`. The compiler validates this protocol before lowering the loop.

Iteration through `opApply`/`opApplyReverse` or a delegate aggregate is
rejected. These callback forms hide control flow behind `foreach` and require a
compiler-generated delegate. Iterate such values with a range, explicit loop,
or explicit calls instead.

Integral and enum `switch`, `final switch`, case ranges, and explicit default
handling are supported. String switches are rejected because D lowers them to
the unavailable `object.__switch` runtime hook. Associative-array iteration is
unavailable with associative arrays. `with` is supported for retained value
types and namespaces; it cannot introduce a rejected object model.

## Inline assembly

Laser-D source does not support inline assembly. Both D-style instruction
blocks and GCC-style extended assembly are rejected. This keeps the language
portable across its required operating systems and architectures and avoids a
source-level dependency on backend-specific assembler dialects. ImportC inline
assembly is separate C input and remains part of the ImportC audit.

## Vector extensions

Laser-D source does not support `__vector` types or the `__simd`, `__simd_sto`,
and `__simd_ib` compiler intrinsics. The target-dependent `D_SIMD`, `D_AVX`,
and `D_AVX2` version identifiers are not predefined. Portable fixed-size arrays
remain supported, and architecture-specific vector implementations may be
provided behind C interfaces. ImportC vector extensions remain a separate part
of the ImportC audit.

## Mutable static storage and native threading

Laser-D source cannot declare mutable global, module, function-static, or
aggregate-static storage. Manifest constants and deeply `immutable` static data
remain available. Native D multithreading constructs (`shared`, `__gshared`,
and `synchronized`) are rejected. Programs may still use C APIs for external
state, threads, atomics, and locks; ImportC globals are exempt.

## Basic declarations and primitive scalar types

Laser-D retains D's `const` read-only view and transitive `immutable`
qualifiers but rejects `inout` in D source. `const` prevents mutation through
the qualified view without promising that the underlying data can never
change. `immutable` denotes data that can never change after initialization;
local immutable values may still be initialized at runtime. Manifest `enum`
values are used when a value must be compile-time known. `const` is a type
qualifier only: postfix `const` member-function qualifiers remain rejected,
as do `inout` wildcard matching and `shared`.

Laser-D retains D's current non-deprecated primitive scalar types except for
`real`, their default initialization, explicit and inferred local variables,
multiple declarations, manifest constants, and basic type or variable aliases.
A local scalar may use a `void` initializer, with the same uninitialized-value
rules as D. Deprecated scalar types are not yet classified.

The `real` source type is rejected because its size, representation, precision,
and ABI behavior vary by target. Laser-D programs use the portable 64-bit
`double` type instead. The frontend continues to retain its internal extended
floating-point representation where required by compile-time evaluation,
ImportC, or the unchanged frontend/backend interface; it cannot be named or
introduced by Laser-D source.

The deprecated `cent`, `ucent`, imaginary, and complex source types are also
rejected. Imaginary literals are unavailable because they introduce an
imaginary type. Their internal representations remain in the frontend and
backend where upstream implementation code or ABI machinery requires them;
Laser-D source cannot name or introduce them.

This decision does not cover pointers, arrays, aggregates, type qualifiers,
function types, storage-duration behavior, module initialization, or advanced
alias/template behavior. Those features are reviewed in their own categories.

## Structs, unions, and enums

Laser-D supports structs and unions as runtime-free value types. Their ordinary
storage, layout, initialization, literals, methods, and constructors do not
require the D runtime. Source-level struct destructors and postblit constructors
are rejected, avoiding implicit lifecycle work during scope exit and copying.
Named and anonymous unions retain D's overlapping-storage rules.

Named, based, anonymous, manifest, and opaque enums are supported when their
base type is otherwise available in Laser-D. Opaque enums have no default
initializer. An enum based on another enum requires explicit member values
after its first member. A named enum member has the named enum type, including
through `typeof`, and constructing that enum type from a value already of the
same enum type preserves the type. Equality and inequality remain valid when
an enum value is viewed through `const`.

Fixed arrays include zero-length arrays and arrays large enough to require
indirect ABI return. A scalar initializer for a zero-length fixed array is
accepted and initializes no elements. Large fixed-array declarations are
limited by the target object representation and compiler resource limits, not
by a Laser-D-specific small-array threshold.
`upstream_compilable_test21039.d` validates the settled zero-length declaration
and initialization boundary; size, alignment, pointers, slicing, and runtime
use remain undecided. `upstream_compilable_fix21684.d` is a large-array
frontend regression guard.

Modern operator overloading has been reviewed separately and is supported under
the restrictions in the operator section. User-defined copy and move
constructors are rejected; ordinary value-copyable structs retain field-wise
copying without user-defined lifecycle hooks. Nested structs are supported only
when they require no hidden enclosing context. Constructor delegation and
explicit `@disable` are rejected. Constructors initialize fields directly, and
Laser-D does not provide attribute-driven nonconstructible or noncopyable value
types.

Private declarations are supported at module and aggregate scope. Their access
boundary is the defining module, including for struct and union fields, methods,
templates, and constructors; `private` is not a per-type friendship boundary.
Code elsewhere in the same module may access a private aggregate member, while
another module may not. A private parameterized constructor can route that
construction form through module functions, but it does not disable a struct's
ordinary default initialization or `.init`. Laser-D rejects `@disable this()`,
so private visibility does not provide a nonconstructible value type.

Aggregate `invariant` declarations are rejected. They introduce implicitly
invoked checking functions and runtime behavior around constructors,
destructors, and public methods. Laser-D programs use ordinary validation
functions when such checks are required, making every invocation explicit.

`alias this` declarations are rejected in both supported D syntaxes. Laser-D
does not implicitly forward member lookup or conversions through an aggregate
member; programs must name the member or conversion operation explicitly.

Bit fields are supported without a preview switch. They are runtime-free and
use the existing frontend/backend interface. Their layout is implementation-
defined, so portable Laser-D code must not assume that bit-field layout is
identical across targets. Code matching an external ABI must verify its layout
on every supported target.

## Classes and interfaces

Native D class and interface declarations are rejected. This includes forward
declarations, definitions, templates, nested declarations, explicit
`extern(D)` declarations, and anonymous class expressions. The native object
model depends on facilities outside Laser-D's reduced runtime model, including
the D class hierarchy and associated runtime metadata.

COM and Objective-C object models are also rejected. The frontend does not
permit declaration of the special `IUnknown` interface from which it derives
COM interface and class behavior, and it rejects `extern(Objective-C)` linkage
for every declaration. Objective-C classes, protocols, methods, and standalone
functions therefore cannot be introduced by Laser-D source.
The predefined `D_ObjectiveC` version is never defined, including on targets
whose unchanged backend has Objective-C capabilities.

C++ interoperability is rejected because maintaining C++ calling conventions,
mangling, type mappings, object layout, lifetime, and exception behavior across
platforms and C++ compiler implementations is outside Laser-D's scope. Every
`extern(C++)` form is rejected, including free functions, function types,
variables, namespaces, overloads, structs, classes, interfaces, templates, and
explicit class/struct mangling forms. C++ libraries must expose a C ABI
boundary.

## ImportC

ImportC is retained. Laser-D can compile C translation units directly and can
compile C modules alongside Laser-D modules so their declarations can be
imported without a handwritten D binding. ImportC remains a C11 compiler; the
restrictions on Laser-D source syntax do not remove C types required to compile
C. For example, C `long double` continues to use the frontend's internal
extended floating-point representation even though Laser-D source cannot name
the D `real` type. ImportC does not admit D declarations, expressions,
templates, attributes, or type syntax into C source. Its reuse of the frontend
AST, semantic analysis, CTFE implementation, optimizer, and backend is an
implementation detail rather than a source-language feature.

The initial ImportC baseline uses preprocessed `.i` translation units and
covers standalone compilation and execution plus
mixed D/C use of functions, globals, structs, unions, enums, function pointers,
initializers, and static assertions. The external preprocessing pipeline,
headers, macros, conditional compilation, atomics, vector extensions, inline
assembly, and implementation-specific C extensions remain to be audited in
separate reviewable categories. The intended extension policy is C11 plus a
small set of individually reviewed GNU-compatible C extensions, not wholesale
compatibility with a vendor extension family.

## Expressions

Laser-D supports basic primary scalar expressions: identifiers, parentheses,
`null`, Boolean literals, literals of the supported integer, floating-point,
and character types, and construction or conversion using a supported scalar
type. The existing type restrictions still apply when a literal or scalar
construction would introduce `real`, an imaginary type, or a complex type.

The `super` expression and its class-hierarchy use in `is` expressions are
rejected. Laser-D structs do not support inheritance, and classes and
interfaces are not part of the language, so there is no valid base object.
ImportC may still use `super` as an ordinary C identifier.

The `__rvalue(expression)` ownership hint and `__rvalue` function attribute are
also rejected. Their explicit move semantics depend on advanced struct
copy/move and destruction behavior that Laser-D does not retain, and they can
leave an original lvalue in an unsafe-to-reuse state without ownership checks.

The `this` expression is supported for struct and union constructors and
instance methods. It denotes the current value and may qualify fields, be
passed or returned by value, have its address taken as a non-owning pointer,
form a struct-method delegate, and participate in `typeof`. Template `this`
parameters may infer the mutable or immutable receiver type at compile time.
None of these forms adds inheritance, a virtual table, allocation, or ownership.
Reference returns, captured receivers, constructor delegation, and `alias this`
remain rejected by their existing rules. An enclosing aggregate instance is
not available: member aggregate types have no outer value, and local structs
requiring hidden context are rejected.

The primary-expression grammar is fully classified. Root-qualified names and
template instances, `$` in indexing, retained literals and type properties,
scalar construction, `typeof`, `is`, parentheses, special keywords, and
non-capturing function literals are supported. Dynamic and associative-array
literals, `typeid`, compile-time import expressions, string mixin expressions,
`new`, `super`, and forms that introduce rejected types remain unavailable
under their individual decisions. Operators, assignment, calls, casts, and
other non-primary expressions retain their individual review status.

## Mixins

String mixins are rejected in every syntactic position: declarations,
statements, expressions, and types. Laser-D source cannot construct source text
and ask the compiler to reparse it. Template mixin declarations and template
mixin instantiations remain supported because they compose already parsed D
declarations rather than reparsing strings.

## Static arrays and slices

Fixed-size arrays and non-owning dynamic-array slices are supported. A slice is
a pointer-and-length view and does not imply garbage-collected ownership. It
may refer to fixed global or stack storage, static string-literal storage, or a
pointer range supplied by manually managed or external code. Indexing,
sub-slicing, `$`, `.ptr`, and read-only `.length` access are supported.
Slice values may be passed, returned, reassigned, compared for identity or
equality when their character element types match, filled in place, and copied
into existing compatible storage. Ordered array and slice comparisons are
rejected because upstream lowers them through the D runtime `object.__cmp`
hook.

String values are not a separate owning type: they are non-owning slices of
immutable `char`, `wchar`, or `dchar` data. UTF-8, UTF-16, and UTF-32 string
literals provide compiler-owned static storage and may be indexed or sliced
without allocation. Their elements cannot be mutated, and a literal cannot be
implicitly converted to a mutable character slice. The conventional `string`,
`wstring`, and `dstring` names are guaranteed by Laser-D's minimal implicit
`object.d` as aliases for `immutable(char)[]`, `immutable(wchar)[]`, and
`immutable(dchar)[]`, respectively. They remain ordinary aliases rather than
intrinsic front-end types and add no runtime or allocation requirement.

Interpolated expression sequences are rejected in double-quoted, backtick, and
token-string forms. Despite their string-like spelling, they produce a
tuple-like sequence of sentinel values, template-instantiated metadata, and
the embedded values rather than a string. Their lowering automatically imports
`core.interpolation` and reparses each embedded expression from stored source
text through an internal string mixin. This conflicts with Laser-D's explicit
argument model and its rejection of text-to-language generation. Programs use
ordinary string literals and explicit formatting or argument passing.

Compile-time initializers for statically allocated fixed-size arrays remain
supported, including context-typed literals such as
`int[3] values = [1, 2, 3]`. The destination supplies inline storage, so this
form performs no allocation. Array literals whose resulting type remains a
dynamic slice, array allocation with `new`,
concatenation, append, `.dup`, `.idup`, `.capacity`, and assignment to dynamic
array `.length` are rejected because they allocate, resize, or depend on GC
allocation metadata. The implicit `object` module does not provide D's
GC-backed `reserve` function. `reserve` is otherwise an ordinary function name,
so explicitly declared non-GC implementations remain callable through UFCS.
Associative-array types and literals are rejected.
Fixed-array dimensions may use manifest integral values. The parser preserves
ambiguous `T[name]` syntax until semantic analysis resolves `name`; value
symbols become fixed-array dimensions, while type symbols are rejected as
associative-array keys.

Built-in associative arrays are rejected as a complete feature rather than
restricted by key or value type. Their hash-table storage, growth, lookup,
removal, iteration, hashing, equality, and destruction depend on hidden runtime
management and type metadata. Programs may instead implement an explicit
container as an ordinary struct over fixed, caller-provided, manually managed,
or C-owned storage, optionally exposing the validated value-range protocol.

The standard library provides `laserd.hash` as one such explicit container. Its
initial API and storage algorithm are a Laser-D port of the public-domain `st`
C hash table: keys and values are 64-bit `size_t` words, caller-supplied
function pointers define hashing and equality, and predefined policies cover
numeric keys, C strings, and ASCII case-insensitive C strings. Entries retain
insertion order. Tables through entry power four have no bin array and use
linear entry search. Larger tables append packed bins to the entry allocation;
bin indices widen from 8 to 16, 32, and 64 bits as the entry power crosses 8,
16, and 32. Rebuilding preserves the original compaction and growth thresholds.
The numeric bit mixing, Murmur-based C-string and incremental hashes,
case-insensitive FNV hash, probing sequence, single-pass insertion reservation,
and rebuild/retry handling around reentrant comparison and iteration callbacks
are retained from the C implementation.

Every table borrows a caller-supplied `laserd.rpmalloc.rpmalloc_heap_t*` for its entire
lifetime. It allocates, grows, compacts, copies, and frees its own table storage
through that heap, but never releases the heap or calls
`rpmalloc_heap_free_all`. The caller must initialize memory, keep the heap
alive until `st_free_table` returns, and serialize access. Creation and copying
report allocation failure with `null`; operations that may grow the table
report `ST_ERROR` without discarding the existing table. The table does not own
pointer-valued keys or values, including C-string key storage.

All `new` expressions are rejected, including scalar, struct, placement, class,
and array forms. Laser-D has no source-level implicit allocation operation.
Programs that need dynamic storage must obtain and release it explicitly, for
example through C interoperability, and initialize supported value types in
that explicitly managed storage.

## Functions, delegates, and closures

Ordinary functions, direct calls, function pointers, and non-capturing function
literals are supported. Delegates are supported as two-word values containing a
context pointer and function pointer; this includes non-capturing delegate
literals and delegates to struct methods.

Capturing delegates are rejected even when the compiler can prove that the
captured context is `scope`. This avoids both hidden heap closures and the
lifetime risks of delegates referring into active stack frames. The restriction
also covers taking the address of a named nested function that captures an
outer local. A struct-method delegate remains supported: its explicit object
context is not a captured lexical frame and follows the same manual lifetime
discipline as other non-owning pointers.

Named nested functions are rejected, including capturing, context-free, and
`static` forms. This prevents direct calls from carrying a hidden enclosing
context and avoids a second local-function form; module-level helpers and
non-capturing function literals cover the explicit alternatives.

C ABI variadic functions declared with `extern(C)` are supported for C
interoperability, including declarations, definitions, function pointers, and
calls. A definition must make the target's `va_list` ABI declarations visible
where required, normally by importing `core.stdc.stdarg`; this supplies ABI
types rather than requiring a D runtime. D-style untyped variadics are rejected
because their hidden TypeInfo
argument protocol requires D runtime machinery. Typesafe runtime variadics,
including lazy variadics, are also rejected because they introduce implicit
argument aggregation and, for lazy parameters, implicit delegates. Variadic
template parameters remain supported: they are a compile-time mechanism and do
not use a runtime variadic calling convention.

Executable Laser-D programs use an explicit C runtime entry point. The only
supported signatures are `extern(C) int main()` and
`extern(C) int main(int argc, char** argv)`. D-linkage `main`, D array
arguments, inferred or non-`int` returns, the POSIX environment-pointer
extension, and the special `WinMain` and `DllMain` entry points are rejected.
The `-main` compiler switch is also rejected because Laser-D does not silently
generate source-level entry points. Libraries need no `main` function.

Frontend-generated helpers required to implement supported structs, templates,
function literals, and other retained constructs remain compiler internals.
They are not additional source-level function forms and must not expose a
rejected runtime protocol.

Language `unittest` blocks are rejected. In BetterC they are compiled as hidden
functions only when `-unittest` is supplied, are not automatically run, and
must be discovered with `__traits(getUnitTests)` and called by user code.
Laser-D instead uses explicit test functions and an explicit C `main`, following
the same visible execution model as ordinary programs. The `-unittest` option
and `__traits(getUnitTests)` are rejected, and the predefined `unittest`
version is never enabled. Runtime assertions remain available independently of
the rejected unit-test framework, while compiler-only `static assert` remains
supported.

Function contracts are rejected. This includes expression and block forms of
`in` preconditions and `out` postconditions, named postcondition results, and
contract-style `do` function bodies. Ordinary functions use a direct `{ ... }`
body and perform any required validation through explicit statements and return
values. This decision does not classify the separate `assert` expression.

## Properties

Compiler-provided properties are supported when their underlying type and
operation are supported. This includes `.init`, `.sizeof`, `.alignof`,
`.stringof`, `.mangleof`, numeric limits and floating-point metadata for the
retained scalar types, aggregate `.tupleof` and field `.offsetof`, enum
properties, read-only array and slice `.length` and `.ptr`, and delegate `.ptr`
and `.funcptr`. Properties tied to rejected types are unavailable, and the
existing array rules continue to reject `.dup`, `.idup`, `.capacity`, and
writes to dynamic-array `.length`.

User-defined `@property` functions are rejected. Although `@property` is a
built-in function attribute rather than a UDA, it makes function calls look
like field reads and writes. Laser-D requires source-defined behavior to use
explicit function-call syntax so that potentially executable operations remain
visible at the call site. Parentheses are mandatory for ordinary function,
method, template, and UFCS calls even when no explicit argument is passed or
all parameters have defaults. Setter-like assignment to a function name is
also rejected.

The floating-point `.im` property is rejected. It is legacy surface associated
with the removed imaginary and complex type family and has no role once those
types are unavailable. This restriction applies only to the compiler-provided
numeric property; aggregates may declare an ordinary field named `im`.

## Operator overloading

Modern operator overloading on structs is supported where the overload itself
uses supported Laser-D types and function features. Unary and binary operators,
right-hand binary dispatch, equality and ordering, casts, calls, assignment and
compound assignment, postfix increment, indexing, index assignment, slicing,
`$`, and `opDispatch` forwarding lower to ordinary or templated method calls and
do not inherently require allocation, TypeInfo, or the D runtime.

Operator hooks remain subject to every cross-cutting Laser-D restriction.
Classes are unavailable, overloads cannot use `const` or `inout`, and they
cannot return by `ref`. Immutable receiver methods remain supported. Index and
slice mutation should use `opIndexAssign`, `opIndexOpAssign`, or their slice
counterparts instead of a reference-returning `opIndex`. Assignment hooks may
return a value or `void` when reference-return chaining is not required.
Postfix operators copy their left operand before invoking the prefix overload;
that is supported for ordinary value-copyable structs, but cannot introduce a
rejected postblit. Any array or slice value produced by an overload remains
subject to the normal non-owning-array restrictions.

Legacy D1-style operator hooks are rejected as aggregate instance methods.
Laser-D uses the modern templated hooks exclusively, avoiding a second set of
names for the same operations.

Modern multidimensional indexing and slicing are supported. Compile-time
dimension arguments to `opSlice` and `opDollar` distinguish each coordinate,
and mixed indices and slice descriptors may be passed to `opIndex`,
`opIndexAssign`, `opIndexOpAssign`, and `opIndexUnary`. The container expression
is evaluated once before these rewrites. Slice descriptor types and backing
storage are ordinary Laser-D values; the feature does not imply dynamic
allocation or GC-backed multidimensional arrays.

## Templates and compile-time execution

The template and CTFE machinery is supported. This includes type, value, alias,
and variadic template parameters; explicit and inferred instantiation;
specialization, defaults, constraints, recursive and eponymous templates;
function, aggregate, alias, enum, and variable templates; and template mixins.
Required instances continue to be emitted in mandatory BetterC mode.

The supported template machinery composes with the retained Laser-D scalar,
immutable, aggregate, bit-field, fixed-array, slice, string, function-pointer,
delegate, cleanup, CTFE, and reflection features. This includes ordinary
constructors in struct templates and templated constructors in ordinary
structs. The frontend's internal reference-return representation for struct
constructors is not exposed as a Laser-D source-level `ref` return.

Compile-time function execution, manifest constants, `__ctfe`, `static if`,
`static foreach`, and `static assert` are supported. Compile-time execution is
not a second language mode: every existing Laser-D restriction also applies in
template declarations, template instances, and CTFE. In particular, templates
and CTFE cannot restore string mixins, GC-backed arrays, associative arrays,
classes, capturing delegates, or any other rejected construct.

Runtime `assert` expressions are supported, including message forms,
`assert(0)`, and assertions in CTFE-capable functions. Laser-D always emits
runtime assertions: `-release`, `-check=assert=off`, and `-checkaction` cannot
remove or redirect them. A false condition calls the existing platform C
runtime assertion-failure entry point directly; it does not use druntime or
the configuration-dependent C `assert` macro. `assert(0)` follows the same
failure path and remains a non-returning expression. During CTFE, an executed
assertion is checked by the compiler. `static assert` remains supported as a
compiler-only check with no runtime dependency, and ImportC retains C
`_Static_assert`.

Compile-time introspection mechanisms such as individual `__traits` operations,
`is` expressions, and `typeof` are documented and tested in their own feature
reviews, even though templates and CTFE may consume their results.

`typeof` and `is` expressions are supported. `typeof` determines an expression
or function return type without evaluating the expression. `is` supports type
validity, equivalence, implicit-conversion tests, type-category tests, and type
pattern deduction. Both mechanisms inspect only the supported Laser-D type
system; they do not make a rejected type or construct available.

Read-only `__traits` reflection is supported for types, values, functions,
parameters, and symbols. This includes semantic probes such as `compiles` and
`isSame`. Predicates that ask about a rejected language kind remain useful to
generic templates, but cannot introduce an instance of that kind. Class and
virtual-method traits consequently have no valid class operands in Laser-D.
On supported x86-64 targets, `isReturnOnStack` reports false for a scalar
`int` result and true for a forty-byte fixed-array struct result.
`getOverloads` excludes template overloads by default and includes them when
its optional inclusion argument is `true`, for both a struct type and a struct
value. Function-literal identity ignores parameter spelling but distinguishes
different expression structure.

The adopted `upstream_compilable_*` tests retain their upstream regression
identity while adding focused evidence for these already supported or refined
boundaries. A passing upstream test is not itself a language decision; its
constructs are first checked against this design and `FEATURE_STATUS.md`.

`__traits(toType)` is rejected because it creates a type from string or mangled
text and crosses the same compile-time text-to-language boundary as rejected
string mixins. `__traits(getPointerBitmap)` is rejected because it exposes
metadata for precise garbage-collector scanning, for which Laser-D has no
runtime contract. `__traits(getUnitTests)` is rejected because language
unit-test declarations and their hidden-function discovery protocol are not
part of Laser-D.

## Compile-time I/O

Language-level compile-time I/O is rejected. Import expressions cannot read
files selected by source code, even when the compiler is given an import-file
path with `-J`. Both declaration and statement forms of `pragma(msg)` are
rejected so compile-time evaluation cannot produce user-selected diagnostic
output.

Other pragma families are not accepted merely because the parser currently
recognizes them. Statement-position pragmas, `pragma(inline)`, and
`pragma(mangle)` remain distinct Undecided features in FEATURE_STATUS.md until
their syntax, targets, diagnostics, portability, and ABI or optimization
effects have focused tests and a decision.

This does not restrict pure CTFE over values already available to the compiler.
It also does not include ordinary compiler diagnostics or compiler-generated
object files and documentation, which are outputs of the compiler rather than
I/O initiated by the compiled language program.

## Modules

The core D module system is supported. A source file may have an explicit
module declaration or derive its module name from its file name. Module names
provide namespace scope, and ordinary, aliased, selective, renamed, static,
private, and public imports retain their D visibility rules. Duplicate imports
and cyclic module graphs are supported; an import cycle does not implicitly
re-export another module's symbols.

Modules support separate compilation. Each source module can be compiled to an
object file while imported source files provide the declarations needed for
semantic analysis. This does not add a Laser-D runtime dependency.

Laser-D does not generate or expose `ModuleInfo` runtime descriptors. Core
module namespace and import behavior does not require them. Module lifecycle
constructors and destructors (`static this()` and `static ~this()`) are also
rejected, including declarations nested in aggregates or templates; these are
still module startup and shutdown hooks. Shared lifecycle forms are rejected by
both this rule and the cross-cutting rejection of `shared`.

Package modules are supported as compile-time namespace facades. A
`package.d` file declares the fully qualified name of its containing package
and may publicly re-export modules from that package. Package modules may be
nested. Package visibility is also supported: an unqualified `package`
declaration is visible within its declaration's package and descendants, while
`package(name)` selects a named ancestor package as that boundary. These
facilities affect lookup only and introduce no runtime state or metadata.
Module deprecation and edition-qualified modules remain undecided.

## Runtime type information

Runtime type information is rejected. Laser-D does not expose Druntime's
`TypeInfo` hierarchy and does not generate type-information objects. Both type
and expression forms of `typeid` are rejected, including uses that upstream D
would evaluate only during CTFE.

This does not restrict compile-time inspection through `typeof`, `is`, or the
supported read-only `__traits` operations. Those mechanisms operate directly
in the frontend and do not create runtime metadata objects.

## User-defined attributes

User-defined attributes are rejected throughout Laser-D source. This includes
argument-list UDAs, identifier and template-instance UDAs, and UDA call
expressions on modules, declarations, functions, parameters, aggregate and
enum members, and other declaration locations. Laser-D therefore has no
source-extensible compile-time annotation mechanism.

Built-in language attributes are distinct from UDAs and retain their individual
feature classifications. Attributes in ImportC input are C implementation
attributes rather than D UDAs and remain governed by the ImportC review.
`__traits(getAttributes)` remains recognized for compatibility with generic D
code, but supported Laser-D source declarations cannot contribute UDAs to its
result.

## C standard library bindings

Laser-D supplies a standard-library source tree under `library/`. The initial
`core.stdc` subset contains C ABI types, constants, and `extern(C)`
declarations derived from druntime and adapted to compile as Laser-D. These
modules do not implement or initialize a D runtime.

The supported initial modules are `config`, `stddef`, `stdint`, `stdarg`,
`stdlib`, `string`, and a basic `stdio` surface. Their function symbols are
provided by the platform C runtime. The compiler therefore emits ordinary C
ABI references which the native linker resolves through the Windows CRT,
Linux libc, or macOS libSystem. No Laser-D static library is required for these
declaration-only modules.

Library APIs are supported only where they have focused cross-platform tests
under `library/test`. Those tests are compiled and linked directly with
Laser-D, separately from the language-conformance suite under
`compiler/test/laser-d`. The remaining upstream `core.stdc` modules are not
implicitly supported merely because their source still exists under druntime.

Laser-D-only conformance runs do not inherit the upstream test harness's
druntime or Phobos import and library search paths. The full host D installation
is used to compile the test tools, while compiler invocations under test retain
only required target flags such as position-independent code on POSIX systems.

Dub builds the compiler executable as `laserd` (`laserd.exe` on Windows),
distinguishing it from the full upstream `dmd` compiler used to bootstrap the
build. CMake owns standard-library C compilation, mixed C/Laser-D integration
tests, installation, and CPack distribution assembly. The installed compiler
configuration locates `import/` relative to the executable, so programs do not
depend on the repository layout. Linux distributions also supply `-fPIC` in
that configuration because contemporary Linux toolchains link executables as
PIE by default.

Laser-D compiler builds and conformance tests currently target x86-64. The test
harness therefore uses model 64 for the Dub-built compiler. A `DMD_MODEL`
override does not expand the supported target set, and selecting model 32 is
rejected by the compiler.

Library source paths mirror their public module packages without an additional
`import` directory. Upstream-compatible modules such as `object` and
`core.stdc` retain their established package names. Laser-D-owned modules and
cross-library facades live under `library/laserd`. Bindings and native adapters
owned by a particular C library live in that library's `laserd` directory,
with native adapter sources below `laserd/c`. All standard-library and native
interop tests live under `library/test`; `compiler/test/laser-d` is reserved
for language and compiler conformance tests.

The first Phobos-derived module is a reduced, source-compatible subset of
`std.traits`. It is maintained as a small Laser-D module rather than a
wholesale copy of the upstream file: the upstream module depends on other
parts of Phobos and contains facilities based on classes, destructors,
postblits, unsupported qualifiers, rejected types, or unreviewed recursive
adaptation. The reduced module contains a commented inventory of deferred
upstream groups so omissions remain visible during review.

`std.traits` initially covers tested qualifier construction for `const` and
`immutable`, function return and parameter inspection, field inspection,
member detection, common type-category predicates, pointer/key/value helpers,
implicit-conversion testing, selection, and mangled-name inspection. A reduced
`std.typecons` is not distributed: without upstream Tuple indexing, named
fields, nullable and ownership wrappers, and other central facilities, the
remaining declarations would overstate compatibility with the Phobos module.

Tests under `library/test` adapt upstream unittest assertions into ordinary
`extern(C) int main()` programs because Laser-D rejects D unittest blocks and
the `-unittest` switch. An upstream declaration is supported only after such
a test is present; unextracted declarations remain outside the library
surface even when their implementation might happen to compile.

The CMake helper compiling Laser-D executables requests a Make-compatible
dependency file from the compiler and registers it with CMake. Changes to
transitively imported `.d` modules therefore rebuild each affected executable
without treating entire import roots as dependencies.

The first production C-backed component is rpmalloc 2.0.1. CMake compiles the
vendored C11 source as `laserd_rpmalloc`, explicitly disables process-wide C
allocator replacement (`ENABLE_OVERRIDE=0`), and enables first-class heaps
(`RPMALLOC_FIRST_CLASS_HEAPS=1`). The reviewed `laserd.rpmalloc` import module
exposes the general allocator, explicit heap API, types, and constants under
their native rpmalloc names. It deliberately adds no D aliases: direct use of
this allocator remains visible at each call site. The public
`rpmalloc_config_t` structure retains rpmalloc's Linux/Android-only field so
its layout matches the native header on every supported platform. Integration testing covers
ordinary allocation, reallocation, aligned allocation, heap ownership, heap
reallocation, zeroed heap allocation, bulk heap cleanup, and finalization.

The `laserd.memory.Arena` facade is created and destroyed explicitly around a
private rpmalloc-backed callback table. Raw and typed allocation and array
allocation return zeroed storage; typed operations request the type's required
alignment while the rpmalloc bridge raises sub-pointer requests to rpmalloc's
minimum accepted alignment. Reallocation callbacks receive both logical old
and new byte sizes. On successful growth they preserve the old region and zero
the newly exposed byte range; on failure the original allocation remains
valid. Typed array allocation rejects size multiplication overflow and returns
a null, zero-length slice for a zero count. Allocations must be expanded and
freed through the same arena, and only complete slices returned by that arena
may be expanded or freed.

The vendored source omits rpmalloc's separate `malloc.c` override
implementation; its include is therefore conditional on `ENABLE_OVERRIDE`, as
is the override functionality itself.

The vendored Foundation C library is built as the `laserd_foundation` static
archive, but its presence does not make every Foundation header a supported
Laser-D API. The initial reviewed surface contains only Base64 encoding and
decoding plus the library's 64-bit Murmur3 hash. These functions are
allocation-free, stateless, callback-free, and portable across the supported
targets; they can therefore be called without Foundation global
initialization. The `laserd.foundation.base64` and
`laserd.foundation.hash` modules expose the exact C entry points and small
slice-based overloads.

Foundation APIs which allocate, own opaque state, require library or thread
initialization, accept callbacks or variadic arguments, or expose operating
system resources remain unexposed. Adding one requires a focused ABI and
ownership review, a documented initialization model where applicable, and a
cross-platform Laser-D integration test. In particular, the MD5 and SHA
contexts are not treated as standalone crypto primitives because their
allocation functions use Foundation's configured global memory system.

Foundation is initialized through a native adapter which supplies rpmalloc as
its `memory_system_t`. The adapter maps ordinary and aligned allocation,
reallocation, deallocation, usable-size queries, zero-initialization hints,
and per-thread allocator lifecycle callbacks. Foundation owns rpmalloc from
successful initialization through finalization; mixing that lifecycle with
independent application calls to `rpmalloc_initialize` or `rpmalloc_finalize`
is unsupported.

The public synchronization layer will not expose Foundation's mutex,
semaphore, or beacon APIs. Those remain implementation details of Foundation.
Laser-D intends to use nsync for public synchronization primitives so that
programs do not have to choose between duplicate locking abstractions.

The initial public Foundation thread interface exposes an opaque `Thread` and
supports callback-based allocation, start, join, deallocation, basic state
queries, thread identifiers, sleep, and yield. A thread callback uses the C ABI
and accepts and returns one opaque pointer. Foundation-created workers enter
and exit Foundation's thread context automatically, which also invokes
rpmalloc's per-thread lifecycle hooks.

Thread signalling and waiting are omitted because they expose Foundation's
internal beacon abstraction. CPU affinity, externally-created thread
registration, and caller-owned thread structures are also deferred pending
focused portability and ownership review.

The process interface uses opaque Foundation process handles. It supports
copied executable paths, working directories and argument arrays; portable
attached/detached, console and standard-stream flags; spawn, wait and kill;
and borrowed stdin, stdout and stderr streams. Process destruction owns and
releases those streams, so callers must not deallocate them independently.
A detached process must be reaped with `wait`, or killed and then reaped,
before its process handle is destroyed.

The shared stream interface is deliberately limited to opaque raw byte
streams. It supports read, write, flush, end-of-stream and available-byte
queries plus destruction. The pipe interface adds unnamed-pipe allocation and
closing of individual endpoints. Stream vtables, typed serialization,
filesystem streams, native descriptors/handles, Windows shell execution,
macOS application launching, and process-global exit functions remain outside
the supported API.

## Synchronization

Laser-D uses the C interface of nsync 1.30.0 for public synchronization.
The C++ variant and nsync's thread-starting test support are not part of the
runtime. The supported build matrix is restricted to x86-64 Windows, Linux,
and macOS.

The public `laserd.thread` module groups thread creation with `Mutex`
reader/writer locks and Mesa-style `Condition` variables rather than exposing
modules or type names after either backing library. Both synchronization
objects are
zero-initializable two-word values. Their layout is fixed at 16 bytes for
Laser-D's supported 64-bit targets and guarded by C and Laser-D compile-time
assertions. They do not allocate through Foundation and do not require
Foundation initialization, although Foundation thread creation does.

nsync implements successful exclusive and reader acquisitions with acquire
operations and releases either mode with release operations on every supported
platform backend. Releasing a mutex therefore happens before a later successful
acquisition of the same mutex. Ordinary data protected by that mutex may be
shared between threads: writes made while holding it are visible after the
later acquisition. Reader acquisitions may overlap only for read-only access;
mutation requires the exclusive mode.

Condition variables add wakeup coordination but no independent publication
mechanism. A wait releases its mutex with release semantics and reacquires it
with acquire semantics before returning. Signal and broadcast do not make
unprotected data safe, so the predicate is changed and tested while holding the
same mutex and is retested in a loop after every wakeup.

Foundation creates threads with the platform thread API. A successful start
publishes argument data initialized before the call to the callback, and a
completed join makes the callback's preceding writes visible to the joining
thread. Referenced argument storage must remain alive through the join.
Laser-D's rejection of `shared` and language-level atomics is unchanged:
programs protect every conflicting concurrent access with `laserd.thread`
mutexes or another explicitly reviewed foreign synchronization API. This is a
library synchronization contract, not a reintroduction of D language-level
threading features.

Portable child-process management, anonymous pipes, and the minimal byte
streams required by both are grouped in `laserd.system`. This keeps backing
library names out of the application-facing module structure while retaining
the native C symbol names at the ABI boundary.

The public thread and system APIs use `Type_operation` names to make the
object being operated on explicit at call sites. A public name is an alias of
the native C function when its signature already expresses the intended API;
a Laser-D wrapper is retained only when it converts a slice to a native
pointer-and-length pair. Native process flags, status values, and thread
priority constants are exposed directly rather than duplicated under a second
set of aliases. Anonymous pipe allocation is a `Stream` operation because the
new pipe is independent of any process object.

Foundation mutexes, semaphores, and beacons remain private implementation
details. Timed waits, cancellation, counters, once execution, wait sets, and
conditional critical sections require separate review before being included
in the supported Laser-D interface.

No archive is produced for `core.stdc` because those modules consist only of
declarations resolved by the platform C runtime. Other standard-library
components may contribute native archives explicitly. Distribution archives
are built and tested independently on Windows, Linux, and macOS.

## Specification organization

The Markdown specification under `spec-markdown/` is the sole normative
language specification and describes Laser-D directly. Retained language
chapters define only constructs which exist in Laser-D and avoid repeatedly
annotating the broader D language. Differences relevant to readers and source
migration are consolidated in `spec-markdown/d-compatibility.md`. Chapters
devoted entirely to absent D features are removed from the Markdown
specification once their decisions have been preserved in that compatibility
document.

The Markdown specification is authoritative and is not regenerated from the
historical Ddoc files. The Ddoc files under `spec/` remain non-normative
upstream review sources: they help identify features and provide provenance for
decisions, but no text in them becomes a Laser-D guarantee unless it is stated
in the Markdown specification. CI runs `tools/check_markdown_docs.py` without
modifying the tree; it verifies chapter metadata, review-source references,
local links, and index coverage.

## Language decision traceability

Language review follows a four-part traceability chain:

1. An upstream D document under `spec/` identifies the source feature or
   behavior being reviewed. This is review provenance, not specification.
2. `FEATURE_STATUS.md` records the Laser-D decision and separately names both
   the normative Laser-D specification and the upstream review source.
3. The applicable chapter under `spec-markdown/` defines the accepted,
   restricted, or rejected Laser-D behavior.
4. Tests under `compiler/test/laser-d` provide executable evidence for the
   language boundary. Library behavior is tested separately under
   `library/test`.

Reviewers must preserve those roles. A `.dd` reference belongs in an
**Upstream review source** field or chapter `review-sources` metadata; it must
not appear as the normative specification for a decided feature. Conversely,
the Markdown specification should describe Laser-D directly rather than
annotating or incorporating the whole upstream chapter. When a review discovers
an untested behavior, it remains **Undecided** until its intended status,
normative wording, and test evidence have been established.

The expression specification follows that organization by documenting only
the reviewed Laser-D core: scalar operators, assignment, explicit calls,
indexing and slicing, supported primary expressions, non-capturing function
literals, and compile-time assertions. Upstream expression semantics which
have not received focused review are not treated as accidental guarantees.
Comma expressions, named arguments, exact evaluation and temporary-lifetime
rules, built-in aggregate equality, membership expressions, numeric edge
semantics, low-level reinterpretation casts, and `delete` are recorded as
distinct undecided features in `FEATURE_STATUS.md`.

The statement specification likewise contains only the reviewed executable
subset: lexical blocks, value returns, `scope(exit)`, compile-time selection,
ordinary loops, direct and range iteration, integral and enum switches,
control transfers, and struct `with`. Unreviewed statement details are tracked
separately for effect-free expression diagnostics, extended foreach
variables, non-struct `with`, and statement pragmas.

`if` declaration conditions are supported for narrowly scoped value checks.
Both inferred and explicitly typed declarations initialize once and test the
resulting value. The declared name exists only in the selected `then` branch,
not in `else` or after the `if`. Declaration conditions in `while`, `switch`,
and `with` remain separate review items.

The error-handling specification defines failure as ordinary program data.
Laser-D APIs use visible status values, output parameters, or result
aggregates; foreign functions retain their documented C error conventions.
Callers propagate failure through ordinary conditions and returns, while
`scope(exit)` provides deterministic lexical cleanup. The upstream discussion
of exception objects, unwinding, and default handlers is not part of the active
Laser-D specification. Mandatory runtime assertions are specified separately
as non-recoverable C-runtime-backed checks, not as error propagation.

The properties specification is limited to reviewed compiler-provided
metadata and representation views: initialization, size and alignment, source
and mangled strings, aggregate fields and offsets, numeric metadata, array and
slice components, delegate components, and enum limits. Absent D property
families remain consolidated in the compatibility notes rather than appearing
as exclusions in the active chapter.

The operator-overloading specification documents modern struct hooks as
ordinary method rewrites, including unary and binary operations, explicit
casts and calls, assignment, indexing, slicing, multidimensional lowering,
`opDispatch`, and immutable receivers. Legacy hooks and attempts to restore
other absent language facilities remain compatibility concerns. Automatic
field-wise equality and membership dispatch are omitted from the normative
chapter while their expression-level behavior remains explicitly undecided.

The templates specification positively defines the retained general-purpose
compile-time machinery: all ordinary parameter kinds, explicit and inferred
instantiation, specialization, constraints, eponymous results, aggregate and
function templates, templated constructors, recursive templates, emission,
and CTFE composition. Template bodies remain ordinary parsed Laser-D code;
the compatibility notes carry the cross-cutting rule that instantiation cannot
restore an absent language facility.

The template-mixin specification covers parsed `mixin template`
declarations and their tested named and unnamed insertion forms at module,
aggregate, template, and function scope. Ordinary templates used as mixin
sources and the extended qualified or alias-style mixin naming grammar remain
separate undecided features rather than implicit guarantees.

The conditional-compilation specification currently defines the verified
core of `static if`, statement-form `static foreach`, and `static assert`.
`version` and `debug` remain outside the normative chapter pending review.
Advanced static-branch scoping and deferral, declaration or multi-binding
`static foreach`, and transfers from static expansions are tracked as distinct
undecided semantics.

The traits specification contains the reviewed compile-time predicates,
representation and layout queries, function and parameter inspection, symbol
and member reflection, declaration metadata, target information, and semantic
probes. Removed trait operations remain in the compatibility notes. The
future-status predicate, child-symbol rebinding, and class-layout or
virtual-member sequence queries are explicitly undecided.

The ImportC specification defines the tested preprocessed-C baseline,
standalone C programs, mixed Laser-D/C compilation, source-language boundary,
and target ABI behavior. Copied upstream tests remain regression evidence
rather than blanket extension guarantees. Preprocessing, the extended
vendor/GNU surface, and C qualifiers beyond `const` stay in the feature ledger
until separately reviewed.

The remaining C++ interoperability experiment was removed after review.
Laser-D now rejects C++ linkage at parse time and has no C++ ABI surface.
The Markdown C++ interoperability chapter was removed; the compatibility notes
record the difference from D.

Laser-D rejects 32-bit targets during option processing. Both `-m32` and the
deprecated `-m32mscoff` alias fail on every host; `-m64` remains the supported
x86-64 target selection.

## Arena allocation backends

`laserd.memory.Arena` provides a common allocation interface with backend-
specific lifetime and concurrency contracts. The rpmalloc-backed arena uses
rpmalloc's allocation and cross-thread-free behavior.

The fixed-region arena owns one zero-initialized backing region and allocates
from it monotonically. Individual frees are no-ops; destroying the arena
releases the complete region. It does not grow or chain additional regions,
and exhaustion returns null without changing existing allocations. Its mutable
allocation cursor is thread-confined and must not be used concurrently.

Aligned allocations align the absolute returned address. Alignment must be a
power of two; zero requests the backend default. Aligned array allocation also
requires the element size to be a multiple of the requested alignment so that
every element, rather than only the first, is correctly aligned. Size
multiplication and alignment padding are checked before advancing the cursor.
