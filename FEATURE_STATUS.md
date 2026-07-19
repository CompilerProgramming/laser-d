# Laser-D language feature status

This document is the working inventory of language features considered for
Laser-D. It records language decisions, not merely the current behavior of the
compiler. The files under `spec/`, the tests under `compiler/test/laser-d`, and
the implementation must ultimately agree with every decided entry.

## Status values

| Status | Meaning |
| --- | --- |
| Supported | The feature is part of Laser-D and must have positive tests. |
| Restricted | A documented subset of the feature is supported; both accepted and rejected boundaries must be tested. |
| Rejected | The feature is not part of Laser-D and must have negative tests. |
| Undecided | No language decision has been made. Current compiler behavior is not normative. |
| Implementation defect | The intended behavior is known, but the compiler does not yet implement it correctly. |

An entry should move out of **Undecided** only after its intended behavior has
been reviewed. Passing or failing an upstream D test is evidence for that
review, but does not by itself decide the status.

## Decided cross-cutting rules

| Feature | Status | Decision | Specification | Laser-D tests |
| --- | --- | --- | --- | --- |
| D source compatibility | Supported | Laser-D introduces no new syntax; every Laser-D program is also a D program. | `DESIGN.md` | Needed |
| BetterC mode | Restricted | BetterC is always enabled and cannot be disabled or weakened by configuration or command-line options; required template instances are emitted without relying on the D runtime. | `DESIGN.md`, `spec/betterc.dd` | `betterc_default.d`, `betterc_mandatory.d`, `betterc_template_emission.d` |
| D runtime | Rejected | Programs may not depend on the D runtime. Only the C runtime is available. | `DESIGN.md`; applicable `spec/` chapters need review | Coverage incomplete |
| Garbage collector | Rejected | GC-dependent language behavior is unavailable. | `DESIGN.md`; `spec/garbage.dd` needs Laser-D wording | Coverage incomplete |
| Function `nothrow` attribute | Restricted | Every function type is implicitly `nothrow`; spelling `nothrow` explicitly is rejected. | `DESIGN.md`, `spec/function.dd`, `spec/attribute.dd` | `implicit_function_attributes.d`, `explicit_function_attributes.d`, `explicit_function_type_attributes.d` |
| Function `@nogc` attribute | Restricted | Every function type is implicitly `@nogc`; spelling `@nogc` explicitly is rejected. | `DESIGN.md`, `spec/function.dd`, `spec/attribute.dd` | `implicit_function_attributes.d`, `explicit_function_attributes.d`, `explicit_function_type_attributes.d` |
| Backend and frontend/backend interface | Supported | Laser-D retains these implementation components unchanged. This does not by itself settle individual source-language features. | `AGENTS.md` project constraint | Not a language conformance test |
| Target operating systems | Supported | Windows, Linux, and macOS are required targets. | `AGENTS.md`; `spec/portability.dd` needs review | Cross-platform CI needed |
| x86-64 | Supported | x86-64 is the initial supported architecture. | `AGENTS.md`; `spec/portability.dd` needs review | Cross-platform CI needed |
| ARM64 | Undecided | Planned when upstream support is suitable; not yet a current language/platform guarantee. | `AGENTS.md` | None |

## Feature inventory by specification chapter

This table is the review queue. A chapter-level **Undecided** entry does not
imply that every construct in that chapter will receive the same final status.
Each chapter should be split into individual features as it is investigated.

| D specification area | Status | Initial Laser-D review questions |
| --- | --- | --- |
| Introduction (`intro.dd`) | Undecided | Replace full-D assumptions with the Laser-D execution and runtime model. |
| Lexical analysis (`lex.dd`) | Undecided | Identify whether all tokens, literals, comments, and identifiers remain available. |
| Interpolated expression sequences (`istring.dd`) | Undecided | Determine generated constructs and any runtime or allocation dependencies. |
| Grammar (`grammar.dd`) | Undecided | Record grammar retained through the no-new-syntax compatibility rule and identify semantically rejected productions. |
| Modules (`module.dd`) | Undecided | Review imports, module constructors/destructors, `ModuleInfo`, and separate compilation. |
| Declarations (`declaration.dd`) | Undecided | Review variables, aliases, linkage, storage classes, and static initialization. |
| Types (`type.dd`) | Undecided | Review basic, pointer, array, associative-array, delegate, class, and function types. |
| Properties (`property.dd`) | Undecided | Identify properties that require runtime support or hidden allocation. |
| Attributes (`attribute.dd`) | Restricted | `nothrow` and `@nogc` are decided; all other attributes remain to be classified. |
| Pragmas (`pragma.dd`) | Undecided | Review each predefined pragma and implementation dependency. |
| Expressions (`expression.dd`) | Undecided | Review allocation, casts, literals, array operations, delegates, assertions, and hidden runtime calls. |
| Statements (`statement.dd`) | Undecided | Review exception statements, synchronization, scope guards, and ordinary control flow. |
| Arrays (`arrays.dd`) | Undecided | Separate static arrays, slices, dynamic arrays, literals, concatenation, resizing, and array operations. |
| Associative arrays (`hash-map.dd`) | Undecided | Determine whether any useful implementation is possible without the D runtime or GC. |
| Structs and unions (`struct.dd`) | Undecided | Review construction, destruction, postblit/copying, nested structs, and generated helpers. |
| Classes (`class.dd`) | Undecided | Review allocation, object model, `Object`, RTTI, virtual dispatch, and destruction separately. |
| Interfaces (`interface.dd`) | Undecided | Review runtime metadata, class dependency, COM/C++ interfaces, and dispatch. |
| Enums (`enum.dd`) | Undecided | Review named, anonymous, manifest, and special enum properties. |
| Type qualifiers (`const3.dd`) | Undecided | Review `const`, `immutable`, `inout`, `shared`, conversions, and initialization. |
| Functions (`function.dd`) | Restricted | Implicit `nothrow` and `@nogc` are decided; review parameters, delegates, closures, nesting, variadics, and generated functions. |
| Operator overloading (`operatoroverloading.dd`) | Undecided | Check lowering for hidden runtime or allocation dependencies. |
| Templates (`template.dd`) | Undecided | Review instantiation, emission, constraints, specialization, and CTFE dependencies. |
| Template mixins (`template-mixin.dd`) | Undecided | Review compile-time-only behavior and generated unsupported constructs. |
| Contracts (`contracts.dd`) | Undecided | Determine assertion failure behavior and runtime dependencies. |
| Conditional compilation (`version.dd`) | Restricted | `D_BetterC` is always defined; review remaining predefined versions and debug behavior. |
| Traits (`traits.dd`) | Undecided | Review traits individually, especially runtime-information and function-attribute queries. |
| Error handling (`errors.dd`) | Undecided | Classify `throw`, `try`, `catch`, `finally`, throwable types, and error-reporting mechanisms. |
| Unit tests (`unittest.dd`) | Undecided | Decide whether language `unittest` blocks are supported and how they run without druntime. |
| Garbage collection (`garbage.dd`) | Rejected | Document the absence of the GC and enumerate rejected or alternative memory-management operations. |
| Floating point (`float.dd`) | Undecided | Review target portability, compile-time behavior, and C runtime dependencies. |
| x86 inline assembler (`iasm.dd`) | Undecided | Decide whether this target-specific feature belongs in the portable subset. |
| Embedded documentation (`ddoc.dd`) | Undecided | Decide whether documentation generation remains a supported compiler facility. |
| C interoperability (`interfaceToC.dd`) | Undecided | Expected to be central; verify types, calling conventions, linking, and C runtime use. |
| C++ interoperability (`cpp_interface.dd`) | Undecided | Review ABI/backend-only features versus constructs requiring D runtime support. |
| Objective-C interoperability (`objc_interface.dd`) | Undecided | Decide whether it is within the initial platform scope. |
| Portability (`portability.dd`) | Restricted | Windows, Linux, macOS, and initially x86-64 are decided; detailed guarantees remain to be written. |
| Named character entities (`entity.dd`) | Undecided | Decide whether this documentation/compiler facility is retained unchanged. |
| Memory safety (`memory-safe-d.dd`) | Undecided | Review `@safe`, `@trusted`, `@system`, inference, and interaction with implicit attributes. |
| ABI (`abi.dd`) | Undecided | The backend and frontend/backend interface are unchanged; determine which source-level ABI guarantees remain part of Laser-D. |
| Vector extensions (`simd.dd`) | Undecided | Review portability and backend support across required targets. |
| BetterC (`betterc.dd`) | Restricted | BetterC is mandatory, but its upstream documentation is not treated as a complete Laser-D specification. |
| ImportC (`importc.dd`) | Undecided | Decide whether ImportC is retained and test interaction with mandatory BetterC. |
| Live functions (`ob.dd`) | Undecided | Review compiler analysis and any runtime assumptions. |
| Windows programming (`windows.dd`) | Undecided | Separate portable language guarantees from Windows-specific interoperability. |
| Legacy features (`legacy.dd`) | Undecided | Decide whether any deprecated or legacy constructs belong in the reduced language. |
| Editions (`editions.dd`) | Undecided | Decide whether edition selection is supported or fixed. |

## Evidence required for a decision

For each feature moved out of **Undecided**, record:

1. The precise accepted or rejected boundary.
2. The relevant `spec/` section and its required Laser-D wording.
3. Minimal positive tests for accepted behavior.
4. Minimal negative tests for rejected behavior.
5. Link or runnable tests when compilation alone cannot prove freedom from D runtime dependencies.
6. Any difference from upstream D or upstream `-betterC` behavior.
7. Any platform-specific result for Windows, Linux, or macOS.

## Maintenance rule

Update this inventory in the same change that identifies or changes a language
feature. Once a decision is made, update the applicable `spec/` source,
`DESIGN.md`, and tests together. Do not silently infer a language decision from
the behavior of the current implementation.
