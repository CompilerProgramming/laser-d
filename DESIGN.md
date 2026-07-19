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

Every function type in Laser-D is implicitly `nothrow` and `@nogc`. These are
language invariants rather than optional annotations: they apply to function
declarations, function pointers, delegates, lambdas, inferred functions, and
functions synthesized by the frontend.

Writing either `nothrow` or `@nogc` explicitly is an error because source code
cannot opt into or out of these invariants. Calls and function-type conversions
therefore always expose both guarantees to the type system.

`compiler/test/laser-d/implicit_function_attributes.d` covers declarations,
external functions, pointers, delegates, inferred return types, member
functions, nested functions, and lambdas. The explicit-attribute tests verify
rejection on declarations, function pointers, and delegate types.

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

## Basic declarations and primitive scalar types

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

This initial expression decision does not classify strings, array or
associative-array literals, function literals, interpolated expressions,
`this`, `super`, `new`, `$`, imports, `typeid`, `is`, traits, type
properties, operators, assignment, calls, casts, or other postfix expressions.
Those forms will be reviewed in smaller dependent categories.

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

Compile-time initializers for statically allocated fixed-size arrays remain
supported. Dynamic array literal expressions, array allocation with `new`,
concatenation, append, `.dup`, `.idup`, `.capacity`, and assignment to dynamic
array `.length` are rejected because they allocate, resize, or depend on GC
allocation metadata. Associative-array types and literals are rejected.
