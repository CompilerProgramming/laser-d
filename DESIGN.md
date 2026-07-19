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
