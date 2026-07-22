# Laser-D design

The working inventory and review status of individual language features is in
[`FEATURE_STATUS.md`](FEATURE_STATUS.md). Language decisions recorded there
must remain consistent with this design, the specification under `spec/`, and
the tests under `compiler/test/laser-d`.

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
does not constitute a source annotation. This removes lifetime annotations,
lazy thunks, inferred reference passing, and reference-return aliasing from
function boundaries.

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
provides no compiler-checked memory-safety boundary; memory correctness remains
the program's responsibility.

The experimental `@live` ownership and borrowing analysis is also rejected.
`@live` cannot be attached to a declaration or function type, and no valid
Laser-D function type carries the live-analysis attribute.

`compiler/test/laser-d/implicit_function_attributes.d` covers declarations,
external functions, pointers, delegates, inferred return types, member
functions, nested functions, and lambdas. The explicit-attribute tests verify
rejection on declarations, function pointers, and delegate types.

## Lexical analysis

## Deterministic cleanup and error handling

Laser-D supports `scope(exit)` as its single source-language cleanup construct.
Source `try`, `catch`, `finally`, `throw`, `scope(success)`, and
`scope(failure)` are rejected. The frontend may still create internal
try/finally nodes when lowering `scope(exit)`; this is implementation machinery,
not an additional source feature. Laser-D programs report and propagate errors
explicitly, for example with return values or C APIs, rather than D exceptions.

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

Laser-D source cannot declare mutable global, module, function-static, or
aggregate-static storage. Manifest constants and deeply `immutable` static data
remain available. Native D multithreading constructs (`shared`, `__gshared`,
and `synchronized`) are rejected. Programs may still use C APIs for external
state, threads, atomics, and locks; ImportC globals are exempt.

Laser-D retains D lexical analysis unchanged. This includes the source
character set, whitespace, comments, identifiers, tokens, literal forms,
escape sequences, keywords, and special tokens. Laser-D restrictions are
applied during parsing or semantic analysis after tokenization; they do not
introduce a separate lexical dialect.

The focused tests in `compiler/test/laser-d/lexical_*.d` cover accepted forms
and representative malformed constructs. The upstream lexer diagnostic tests
were also compared between upstream DMD in BetterC mode and Laser-D; the
rejection results matched for the reviewed cases.

## Basic declarations and primitive scalar types

Laser-D retains D's transitive `immutable` qualifier but rejects `const` and
`inout` in D source. `immutable` denotes data that can never change after
initialization; local immutable values may still be initialized at runtime.
Manifest `enum` values are used when a value must be compile-time known.
ImportC retains C `const` declarations and any frontend-internal qualifier
representation. `inout` wildcard matching is unnecessary without the full
mutable/const/immutable qualifier family and is not part of Laser-D.

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
after its first member.

Advanced aggregate behavior coupled to later categories—including advanced
copy and move constructors and overloaded operators—remains undecided until
those dependent categories are reviewed.

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

C++ classes and interfaces are rejected because maintaining their object-model
ABI across platforms and C++ compiler implementations is outside Laser-D's
scope. This includes forward declarations, definitions, templates, and the
`extern(C++, class)` and `extern(C++, struct)` class-mangling forms.

This decision does not remove C++ linkage itself. `extern(C++)` free functions
remain supported, including overloads. C++ structs are rejected as well: their
non-virtual value-type model still requires platform- and compiler-specific
layout, mangling, constructor, destructor, and copying ABI support.

## ImportC

ImportC is retained. Laser-D can compile C translation units directly and can
compile C modules alongside Laser-D modules so their declarations can be
imported without a handwritten D binding. ImportC remains a C11 compiler; the
restrictions on Laser-D source syntax do not remove C types required to compile
C. For example, C `long double` continues to use the frontend's internal
extended floating-point representation even though Laser-D source cannot name
the D `real` type.

The initial ImportC baseline uses preprocessed `.i` translation units and
covers standalone compilation and execution plus
mixed D/C use of functions, globals, structs, unions, enums, function pointers,
initializers, and static assertions. The external preprocessing pipeline,
headers, macros, conditional compilation, atomics, vector extensions, inline
assembly, and implementation-specific C extensions remain to be audited in
separate reviewable categories.

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

Interpolated expressions, `this`, non-array type properties, operators,
assignment, calls, casts, and other postfix expressions retain their individual
review status. Other primary forms are recorded in the feature inventory.

### Mixins

String mixins are rejected in every syntactic position: declarations,
statements, expressions, and types. Laser-D source cannot construct source text
and ask the compiler to reparse it. Template mixin declarations and template
mixin instantiations remain supported because they compose already parsed D
declarations rather than reparsing strings.

### Static arrays and slices

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
`wstring`, and `dstring` names are aliases normally supplied by `object.d`, not
intrinsic front-end types.

Compile-time initializers for statically allocated fixed-size arrays remain
supported. Dynamic array literal expressions, array allocation with `new`,
concatenation, append, `.dup`, `.idup`, `.capacity`, and assignment to dynamic
array `.length` are rejected because they allocate, resize, or depend on GC
allocation metadata. Associative-array types and literals are rejected.

All `new` expressions are rejected, including scalar, struct, placement, class,
and array forms. Laser-D has no source-level implicit allocation operation.
Programs that need dynamic storage must obtain and release it explicitly, for
example through C interoperability, and initialize supported value types in
that explicitly managed storage.

### Functions, delegates, and closures

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

This first function review does not yet classify the complete parameter model,
variadic functions, nested named functions, function contracts, or generated
special member functions.

### Properties

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

The floating-point `.im` property requires a separate decision because it is
legacy surface associated with the removed imaginary and complex type family.

### Operator overloading

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

### Templates and compile-time execution

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

`__traits(toType)` is rejected because it creates a type from string or mangled
text and crosses the same compile-time text-to-language boundary as rejected
string mixins. `__traits(getPointerBitmap)` is rejected because it exposes
metadata for precise garbage-collector scanning, for which Laser-D has no
runtime contract. `__traits(getUnitTests)` is deferred until language unit-test
declarations and execution are reviewed.

### Compile-time I/O

Language-level compile-time I/O is rejected. Import expressions cannot read
files selected by source code, even when the compiler is given an import-file
path with `-J`. Both declaration and statement forms of `pragma(msg)` are
rejected so compile-time evaluation cannot produce user-selected diagnostic
output.

This does not restrict pure CTFE over values already available to the compiler.
It also does not include ordinary compiler diagnostics or compiler-generated
object files and documentation, which are outputs of the compiler rather than
I/O initiated by the compiled language program.

### Modules

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
both this rule and the cross-cutting rejection of `shared`. Package modules and
visibility, module deprecation, and edition-qualified modules remain undecided.

### Runtime type information

Runtime type information is rejected. Laser-D does not expose Druntime's
`TypeInfo` hierarchy and does not generate type-information objects. Both type
and expression forms of `typeid` are rejected, including uses that upstream D
would evaluate only during CTFE.

This does not restrict compile-time inspection through `typeof`, `is`, or the
supported read-only `__traits` operations. Those mechanisms operate directly
in the frontend and do not create runtime metadata objects.

### User-defined attributes

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
