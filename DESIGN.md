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
storage, layout, initialization, literals, methods, constructors, destructors,
postblits, and generated helpers do not require the D runtime. Named and
anonymous unions retain D's overlapping-storage rules.

Named, based, anonymous, manifest, and opaque enums are supported when their
base type is otherwise available in Laser-D. Opaque enums have no default
initializer. An enum based on another enum requires explicit member values
after its first member.

Advanced aggregate behavior coupled to later categories—including bit fields,
advanced copy and move constructors, `alias this`, and overloaded operators—
remains undecided until those dependent categories are reviewed.

Aggregate `invariant` declarations are rejected. They introduce implicitly
invoked checking functions and runtime behavior around constructors,
destructors, and public methods. Laser-D programs use ordinary validation
functions when such checks are required, making every invocation explicit.
