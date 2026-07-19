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
| Lexical analysis (`lex.dd`) | Supported | Laser-D retains D source text, whitespace, comments, identifiers, tokens, literals, escape sequences, keywords, and special tokens unchanged. Malformed lexical constructs are rejected according to the D lexical grammar. See the detailed lexical decisions below. |
| Interpolated expression sequences (`istring.dd`) | Undecided | Determine generated constructs and any runtime or allocation dependencies. |
| Grammar (`grammar.dd`) | Undecided | Record grammar retained through the no-new-syntax compatibility rule and identify semantically rejected productions. |
| Modules (`module.dd`) | Undecided | Review imports, module constructors/destructors, `ModuleInfo`, and separate compilation. |
| Declarations (`declaration.dd`) | Restricted | Basic variables, manifest constants, inference, aliases, multiple declarations, and scalar initialization are supported. Linkage, most storage classes, static initialization, and declarations involving derived types remain to be reviewed. |
| Types (`type.dd`) | Restricted | Current non-deprecated primitive scalar types are supported. Deprecated scalar types and all derived or user-defined types are classified separately or remain to be reviewed. |
| Properties (`property.dd`) | Undecided | Identify properties that require runtime support or hidden allocation. |
| Attributes (`attribute.dd`) | Restricted | `nothrow` and `@nogc` are decided; all other attributes remain to be classified. |
| Pragmas (`pragma.dd`) | Undecided | Review each predefined pragma and implementation dependency. |
| Expressions (`expression.dd`) | Undecided | Review allocation, casts, literals, array operations, delegates, assertions, and hidden runtime calls. |
| Statements (`statement.dd`) | Undecided | Review exception statements, synchronization, scope guards, and ordinary control flow. |
| Arrays (`arrays.dd`) | Undecided | Separate static arrays, slices, dynamic arrays, literals, concatenation, resizing, and array operations. |
| Associative arrays (`hash-map.dd`) | Undecided | Determine whether any useful implementation is possible without the D runtime or GC. |
| Structs and unions (`struct.dd`) | Restricted | Value storage, layout, fields, literals, methods, constructors, destructors, postblits, bit fields, named and anonymous unions, and ordinary initialization are supported without the D runtime. Invariant and `alias this` declarations are rejected. Advanced copy/move constructors and operator-specific behavior remain classified with their dependent feature categories. |
| Classes (`class.dd`) | Restricted | Native D class declarations and anonymous classes are rejected. Foreign object models remain undecided and will be reviewed with C++, COM, and Objective-C interoperability. |
| Interfaces (`interface.dd`) | Restricted | Native D interface declarations are rejected. C++, COM, and Objective-C interfaces remain undecided. |
| Enums (`enum.dd`) | Supported | Named, anonymous, manifest, based, and opaque enum declarations and ordinary enum properties are supported. Opaque enums have no default initializer, and automatic numbering is rejected when the base type is itself an enum. |
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

## Lexical feature decisions

| Feature | Status | Decision | Tests |
| --- | --- | --- | --- |
| Source text and character set | Supported | UTF-8, UTF-16LE, UTF-16BE, and UTF-32LE source text with byte-order marks, plus Unicode characters, are retained. | `lexical_accepted.d`; upstream BOM fixtures used as differential evidence |
| Whitespace and line endings | Supported | D whitespace and end-of-line rules are retained. | `lexical_accepted.d` |
| Comments | Supported | Line, block, and nesting block comments are retained; unterminated comments are rejected. | `lexical_accepted.d`, `lexical_unterminated_comment.d` |
| Identifiers | Supported | ASCII and universal-alpha identifiers, case sensitivity, and D reserved-identifier rules are retained. | `lexical_accepted.d`; `lexer23465.d` used as differential evidence |
| Integer literals | Supported | D decimal, binary, and hexadecimal integer literals, separators, and suffixes are retained; malformed digits and overflow are rejected. | `lexical_accepted.d`, `lexical_invalid_number.d`; upstream `lexer4.d` and `lexer23465.d` used as differential evidence |
| Floating-point literal tokens | Supported | D decimal and hexadecimal floating-point tokens remain lexically valid. Literals that produce the rejected `real` or imaginary types are rejected during parsing; malformed or unrepresentable literals are also rejected. | `lexical_accepted.d`, `real_rejected.d`, `imaginary_rejected.d`; upstream `lexer4.d` and `lexer5.d` used as differential evidence |
| Character literals and escapes | Supported | D character literals, escape sequences, Unicode escapes, and named character entities are retained; malformed escapes are rejected. | `lexical_accepted.d`, `lexical_invalid_escape.d`; upstream `lexer1.d` used as differential evidence |
| String literals | Supported | Quoted, WYSIWYG, delimited, token, hexadecimal, and postfix string literals are retained. | `lexical_accepted.d`; upstream `lexer1.d`, `lexer2.d`, and `lexer3.d` used as differential evidence |
| Keywords and tokens | Supported | D keywords, operators, punctuation, and tokenization rules are retained unchanged. | Exercised throughout the Laser-D suite; upstream lexer diagnostics used as differential evidence |
| Special tokens | Supported | D special tokens such as `__FILE__`, `__LINE__`, and `__MODULE__` are retained. | `lexical_accepted.d` |

## Basic declaration and primitive-type decisions

| Feature | Status | Decision | Tests |
| --- | --- | --- | --- |
| `void` | Supported | `void` is retained as the no-value function result type, but variables cannot have type `void`. | `basic_void_variable_rejected.d`; existing function tests |
| Boolean type | Supported | `bool` and its `false` default initializer are retained. | `basic_declarations_accepted.d` |
| Integer types | Supported | `byte`, `ubyte`, `short`, `ushort`, `int`, `uint`, `long`, and `ulong` and their D default initializers are retained. | `basic_declarations_accepted.d` |
| Floating-point types | Restricted | `float` and `double` are supported. The source type `real`, `L`-suffixed real literals, and `real` type properties are rejected. | `basic_declarations_accepted.d`, `real_rejected.d` |
| Character types | Supported | `char`, `wchar`, and `dchar` and their D default initializers are retained. | `basic_declarations_accepted.d` |
| Null type | Supported | `typeof(null)` and the `null` initializer are retained. | `basic_declarations_accepted.d` |
| 128-bit integer types | Rejected | `cent` and `ucent` cannot be named or introduced by Laser-D source. Their internal representations remain available to the unchanged frontend/backend interface. | `cent_ucent_rejected.d` |
| Imaginary types | Rejected | `ifloat`, `idouble`, `ireal`, and imaginary literals are not part of Laser-D. | `imaginary_rejected.d` |
| Complex types | Rejected | `cfloat`, `cdouble`, and `creal` are not part of Laser-D. | `complex_rejected.d` |
| Explicit and inferred variables | Supported | Explicit scalar declarations, initialized `auto` declarations, multiple declarations, default initialization, and local `void` initialization are retained. An `auto` declaration without an initializer is rejected. | `basic_declarations_accepted.d`, `basic_auto_without_initializer_rejected.d` |
| Manifest constants | Supported | Basic `enum` manifest constants are retained; enum types will be reviewed with aggregates and enums. | `basic_declarations_accepted.d` |
| Basic aliases | Supported | Aliases of primitive types and variables are retained. More advanced alias behavior remains with templates and other feature categories. | `basic_declarations_accepted.d`; upstream `aliasassign.d` used as differential evidence |
| Invalid and duplicate declarations | Rejected | Undeclared type names, `void` variables, missing inference initializers, and duplicate names are rejected. | `basic_unknown_type_rejected.d`, `basic_void_variable_rejected.d`, `basic_auto_without_initializer_rejected.d`, `basic_duplicate_declaration_rejected.d` |

## Struct, union, and enum decisions

| Feature | Status | Decision | Tests |
| --- | --- | --- | --- |
| Struct storage and layout | Supported | Structs are value types with D field ordering, alignment, size, and offset rules. Direct recursive storage is rejected because it has no finite size. | `aggregate_types_accepted.d`, `recursive_struct_rejected.d` |
| Struct initialization and literals | Supported | Default initialization, field-value literals, and scalar-field initialization are supported. Initialization involving a separately restricted field type remains subject to that type's restriction. | `aggregate_types_accepted.d` |
| Struct methods and lifecycle | Supported | Runtime-free methods, constructors, destructors, and postblits are supported and generated helper functions inherit Laser-D's implicit function attributes. | `aggregate_types_accepted.d`; upstream `struct_allMembers.d` used as differential evidence |
| Aggregate invariants | Rejected | `invariant` declarations are not part of Laser-D. Programs must use explicitly called validation functions when they require consistency checks. | `invariant_rejected.d` |
| Alias this | Rejected | Both `alias member this` and `alias this = member` declarations are rejected. Laser-D does not perform implicit member forwarding or conversion through `alias this`. | `alias_this_rejected.d` |
| Bit fields | Supported | Integral signed and unsigned bit fields, default initializers, anonymous and zero-width alignment fields, struct and union storage, access, assignment, and bit-field traits are supported without a preview switch. Layout remains implementation-defined and must not be assumed portable without target-specific verification. | `bitfields_accepted.d`; upstream `dbitfields.d` used as differential evidence |
| Invalid bit fields | Rejected | Non-integral fields, widths larger than their storage type, and named zero-width fields are rejected. | `bitfield_non_integral_rejected.d`, `bitfield_width_rejected.d`, `bitfield_named_zero_width_rejected.d` |
| Advanced struct behavior | Undecided | Advanced copy/move constructors and operator-specific behavior will be decided with their dependent function, expression, or operator categories. | None |
| Union storage and layout | Supported | Named and anonymous unions overlay their fields according to D layout rules. Union constructors and ordinary initialization are supported. | `aggregate_types_accepted.d`; upstream `union_initialization.d` used as differential evidence |
| Union default initialization | Restricted | At most one overlapping field may have a default initializer. | `union_overlapping_initializers_rejected.d` |
| Named and based enums | Supported | Named enums with primitive or enum base types, explicit values, ordinary auto-increment, and `.init`, `.min`, `.max`, and `.sizeof` properties are supported. | `aggregate_types_accepted.d` |
| Anonymous enums and manifest constants | Supported | Anonymous enum members and basic manifest constants are supported. | `aggregate_types_accepted.d` |
| Opaque enums | Restricted | Opaque enums with a known base type are supported as types, but have no default initializer until defined. | `aggregate_types_accepted.d`, `opaque_enum_default_rejected.d` |
| Enum-based auto-increment | Restricted | When an enum's base type is another enum, members after the first require explicit values. | `enum_auto_increment_rejected.d` |

## Class and interface decisions

| Feature | Status | Decision | Tests |
| --- | --- | --- | --- |
| Native D classes | Rejected | Plain and explicit `extern(D)` class declarations are rejected, including forward declarations, definitions, templates, nested classes, and anonymous class expressions. | `native_class_rejected.d`, `native_anonymous_class_rejected.d` |
| Native D interfaces | Rejected | Plain and explicit `extern(D)` interface declarations are rejected, including forward declarations, definitions, templates, and nested interfaces. | `native_interface_rejected.d` |
| Foreign classes and interfaces | Undecided | C++, COM, and Objective-C object models are outside this decision and will be reviewed with their interoperability categories. A boundary regression verifies that the native-D parser restriction does not reject C++ declarations; it does not establish full support. | `foreign_object_declarations_retained.d` |

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
