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
| Garbage collector | Rejected | Laser-D has no garbage collector or D runtime memory manager. Storage is automatic, inline, immutable static, caller-provided, or obtained through an explicit foreign API; ownership and release remain the program's responsibility. | `DESIGN.md`; `spec/garbage.dd` | `new_expressions_rejected.d`, `new_array_rejected.d`, array-allocation rejection tests, `traits_removed_operations_rejected.d` |
| Function `nothrow` attribute | Restricted | Every function type is implicitly `nothrow`; spelling `nothrow` explicitly is rejected. | `DESIGN.md`, `spec/function.dd`, `spec/attribute.dd` | `implicit_function_attributes.d`, `explicit_function_attributes.d`, `explicit_function_type_attributes.d` |
| Function `@nogc` attribute | Restricted | Every function type is implicitly `@nogc`; spelling `@nogc` explicitly is rejected. | `DESIGN.md`, `spec/function.dd`, `spec/attribute.dd` | `implicit_function_attributes.d`, `explicit_function_attributes.d`, `explicit_function_type_attributes.d` |
| Function safety attributes | Restricted | Every function and function type is implicitly `@system`; `@safe`, `@trusted`, and explicit `@system` are rejected, and safety inference is disabled. | `DESIGN.md`, `spec/function.dd`, `spec/attribute.dd`, `spec/memory-safe-d.dd` | `implicit_function_attributes.d`, `explicit_safety_attributes_rejected.d` |
| Disable attribute | Rejected | Explicit `@disable` is rejected. Laser-D does not use an attribute to create unavailable declarations or nonconstructible/noncopyable value types. | `DESIGN.md`, `spec/attribute.dd`, `spec/struct.dd` | `disable_attribute_rejected.d` |
| Function purity | Rejected | D functions remain conservatively impure; explicit `pure` and purity inference are rejected. ImportC behavior is preserved. | `DESIGN.md`, `spec/function.dd`, `spec/attribute.dd` | `threading_and_purity_rejected.d`, `implicit_function_attributes.d` |
| Mutable static storage | Rejected | Mutable global, module, function-static, and aggregate-static storage is rejected. Manifest constants, deeply immutable static data, and ImportC globals remain supported. | `DESIGN.md`, `spec/declaration.dd`, `spec/module.dd` | `mutable_static_storage_rejected.d`, `mutable_local_static_storage_rejected.d`, `immutable_static_storage_accepted.d` |
| Type qualifiers | Restricted | D-source `const`, `inout`, and `shared` are rejected. `immutable` retains its transitive D semantics and may be initialized at runtime for local values; manifest `enum` values represent compile-time constants. ImportC qualifiers are preserved. | `DESIGN.md`, `spec/const3.dd`, `spec/type.dd` | `const_rejected.d`, `inout_rejected.d`, `immutable_accepted.d`, `immutable_static_storage_accepted.d`, ImportC fixtures |
| Native multithreading | Rejected | `shared`, `__gshared`, and `synchronized` are rejected in Laser-D source. C threading and atomics remain accessible through ImportC. | `DESIGN.md`, `spec/attribute.dd`, `spec/statement.dd` | `threading_and_purity_rejected.d`, `gshared_rejected.d` |
| Exceptions and cleanup | Restricted | D exceptions and source `try`/`finally` are rejected. `scope(exit)` is the sole deterministic-cleanup syntax; `scope(success)` and `scope(failure)` are rejected. Internal try/finally nodes used to lower `scope(exit)` remain implementation details. | `DESIGN.md`, `spec/statement.dd`, `spec/errors.dd` | `scope_exit_accepted.d`, `exception_statements_rejected.d`, `scope_success_failure_rejected.d` |
| Ordinary control flow | Supported | Scalar conditionals and loops, direct fixed-array/slice and numeric-range iteration, integral and enum switches, labels, control transfers, and value-type `with` statements are supported. Active `scope(exit)` guards run when control leaves their scopes. | `DESIGN.md`, `spec/statement.dd` | `structured_control_flow_accepted.d`, `control_transfers_accepted.d` |
| Compile-time sequence iteration | Supported | Both `static foreach` and ordinary `foreach` over compile-time tuples and sequences are expanded by the frontend without a runtime iteration protocol. | `DESIGN.md`, `spec/statement.dd` | `ctfe_accepted.d`, `compile_time_iteration_accepted.d` |
| Value-type ranges | Restricted | Struct ranges are supported through validated parameterless instance methods: `empty()` returns `bool`; `front()`/`back()` returns a supported non-`ref` value; and `popFront()`/`popBack()` returns `void`. | `DESIGN.md`, `spec/statement.dd` | `range_iteration_accepted.d`, `range_iteration_invalid_rejected.d` |
| Callback iteration protocols | Rejected | Struct `opApply`/`opApplyReverse` and delegate aggregates are rejected; ranges, explicit loops, or explicit calls must be used. | `DESIGN.md`, `spec/statement.dd` | `opapply_iteration_rejected.d`, `delegate_iteration_rejected.d` |
| String switches | Rejected | Switching on strings or character slices is rejected because D lowers it through the unavailable `object.__switch` runtime hook. | `DESIGN.md`, `spec/statement.dd` | `string_switch_rejected.d` |
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
| Interpolated expression sequences (`istring.dd`) | Rejected | All string-like IES forms are rejected. Their tuple-like lowering automatically imports `core.interpolation`, creates template metadata, and reparses embedded source text through an internal string mixin. |
| Grammar (`grammar.dd`) | Undecided | Record grammar retained through the no-new-syntax compatibility rule and identify semantically rejected productions. |
| Modules (`module.dd`) | Restricted | Core module declarations, namespaces, imports, re-exports, cycles, and separate compilation are supported. `ModuleInfo` and all module lifecycle constructors and destructors are rejected; package-specific facilities require separate review. |
| Declarations (`declaration.dd`) | Restricted | Basic variables, manifest constants, inference, aliases, multiple declarations, and scalar initialization are supported. Linkage, most storage classes, static initialization, and declarations involving derived types remain to be reviewed. |
| Types (`type.dd`) | Restricted | Current non-deprecated primitive scalar types and compile-time inspection with `typeof` and `is` are supported. Deprecated scalar types and derived or user-defined types follow their individual classifications. |
| Properties (`property.dd`) | Restricted | Runtime-free compiler-provided properties are supported. User-defined `@property` functions and function calls without parentheses are rejected so calls cannot masquerade as fields. Properties tied to rejected types or GC-backed array operations remain rejected. The legacy floating-point `.im` property is rejected with the imaginary and complex type model. |
| Attributes (`attribute.dd`) | Restricted | User-defined attributes are rejected. `nothrow` and `@nogc` are implicit and cannot be spelled explicitly; other built-in attributes remain to be classified. |
| Pragmas (`pragma.dd`) | Undecided | Review each predefined pragma and implementation dependency. |
| Expressions (`expression.dd`) | Restricted | Basic primary scalar expressions are supported. Dynamic and associative-array literals, GC-backed array allocation, concatenation, and append are rejected. Remaining forms and operators are reviewed by category. |
| Statements (`statement.dd`) | Restricted | Ordinary scalar control flow, direct array/slice, numeric-range, validated value-range, and compile-time-sequence iteration, integral/enum switches, transfers, value-type `with`, and `scope(exit)` are supported. Callback iteration, string switches, exceptions, other scope guards, and synchronization are rejected. |
| Arrays (`arrays.dd`) | Restricted | Fixed-size arrays and non-owning slices are supported, including indexing, sub-slicing, `$`, `.ptr`, read-only `.length`, pointer slicing, and static-storage string literals. GC-backed allocation, copying, capacity management, resizing, concatenation, and append are rejected. |
| Associative arrays (`hash-map.dd`) | Rejected | Associative-array types and literals are rejected. |
| Structs and unions (`struct.dd`) | Restricted | Value storage, layout, fields, literals, methods, direct field-initializing constructors, bit fields, named and anonymous unions, ordinary initialization, and context-free local structs are supported. Struct destructors, postblits, copy/move constructors, constructor delegation, invariants, `alias this`, and hidden-context structs are rejected. Modern operators are classified separately. |
| Classes (`class.dd`) | Rejected | Native D, COM, Objective-C, and C++ classes are rejected, including forward, templated, nested, and anonymous forms. Laser-D has no class references, inheritance, virtual dispatch, class metadata, monitors, or class lifecycle. |
| Interfaces (`interface.dd`) | Rejected | Native D, COM, Objective-C, and C++ interfaces are rejected, including forward, templated, nested, inherited, and protocol forms. Laser-D has no interface references, implicit implementation conversion, virtual dispatch, interface metadata, or object-model ABI. |
| Enums (`enum.dd`) | Supported | Named, anonymous, manifest, based, and opaque enum declarations and ordinary enum properties are supported. Opaque enums have no default initializer, and automatic numbering is rejected when the base type is itself an enum. |
| Type qualifiers (`const3.dd`) | Restricted | `immutable` is supported with normal transitive semantics, including runtime initialization of locals, eligible static initialization, immutable receiver methods, and conversions that preserve permanent immutability. `const`, `inout`, and `shared` are rejected. ImportC retains C qualifiers. |
| Functions (`function.dd`) | Restricted | Ordinary declarations, bodies, prototypes, calls, value returns and inference, static overloads, `in`/`out`/`ref` parameters, default arguments, automatic locals, function pointers, non-capturing literals/delegates, method delegates, UFCS, templates, CTFE, C ABI variadics, and the two standard C `main` signatures are supported under the fixed function model. Rejected attributes, contracts, reference returns, lifetime annotations, lazy parameters, closure capture, named nested functions, D runtime variadics, generated or platform-specific entry points, virtual dispatch, property calls, and optional parentheses are rejected. |
| Operator overloading (`operatoroverloading.dd`) | Restricted | Modern struct operator hooks, including multidimensional indexing and slicing, are supported and lower to ordinary calls without inherent runtime allocation. Hooks remain subject to Laser-D type and function restrictions. Legacy D1 hooks are rejected. |
| Templates (`template.dd`) | Supported | Template declaration, selection, instantiation, inference, specialization, constraints, recursion, and emission are supported. Template contents remain subject to every Laser-D language restriction. |
| Template mixins (`template-mixin.dd`) | Supported | Mixin template declarations and template mixin instantiations are supported; string mixins are rejected separately. |
| Function contracts (`contracts.dd`) | Rejected | Expression and block `in` preconditions, `out` postconditions, named results, and contract-style `do` bodies are rejected. Validation uses visible ordinary control flow and explicit result handling. Runtime assertions are rejected separately. |
| Conditional compilation (`version.dd`) | Restricted | `D_BetterC` is always defined; review remaining predefined versions and debug behavior. |
| Traits (`traits.dd`) | Restricted | Read-only type, function, parameter, and symbol reflection is supported. `__traits(toType)`, `__traits(getPointerBitmap)`, and `__traits(getUnitTests)` are rejected. |
| Error handling (`errors.dd`) | Restricted | D exceptions are rejected. Errors must be represented and propagated explicitly, such as through return values or C APIs. `scope(exit)` provides deterministic cleanup. |
| Unit tests (`unittest.dd`) | Rejected | Language `unittest` blocks, `-unittest`, `__traits(getUnitTests)`, and the predefined `unittest` version are unavailable. Tests are explicit Laser-D programs with an explicit C entry point. |
| Garbage collection (`garbage.dd`) | Rejected | There is no garbage collector or implicit language allocation. Fixed storage and non-owning views remain available; explicitly called foreign allocators are governed by their own ownership contracts. |
| Floating point (`float.dd`) | Undecided | Review target portability, compile-time behavior, and C runtime dependencies. |
| Inline assembler (`iasm.dd`) | Rejected | D-style and GCC-style inline assembly are rejected on every target. Architecture-specific implementations may be linked behind an explicit foreign-function boundary; ImportC assembly remains a separate undecided feature. |
| Embedded documentation (`ddoc.dd`) | Undecided | Decide whether documentation generation remains a supported compiler facility. |
| C interoperability (`interfaceToC.dd`) | Undecided | Expected to be central; verify types, calling conventions, linking, and C runtime use. |
| C++ interoperability (`cpp_interface.dd`) | Restricted | C++ classes, interfaces, and structs are rejected. C++ free-function linkage is supported; the remaining interoperability surface is undecided. |
| Objective-C interoperability (`objc_interface.dd`) | Rejected | Objective-C linkage and its classes, protocols, methods, functions, message dispatch, metadata, and ownership conventions cannot be declared in Laser-D source. `D_ObjectiveC` is never predefined; C-callable wrappers remain possible. |
| Portability (`portability.dd`) | Restricted | Windows, Linux, macOS, and initially x86-64 are decided; detailed guarantees remain to be written. |
| Named character entities (`entity.dd`) | Undecided | Decide whether this documentation/compiler facility is retained unchanged. |
| Memory safety (`memory-safe-d.dd`) | Rejected | The checked `@safe` subset and `@trusted` boundary are not part of Laser-D. Every function is implicitly `@system`, with no safety inference or explicit safety annotations; bounds, lifetime, ownership, and foreign-call validity remain programmer responsibilities. |
| ABI (`abi.dd`) | Undecided | The backend and frontend/backend interface are unchanged; determine which source-level ABI guarantees remain part of Laser-D. |
| Vector extensions (`simd.dd`) | Rejected | `__vector` types, compiler SIMD intrinsics, and SIMD/AVX predefined versions are rejected in Laser-D source. Fixed-size arrays remain ordinary value storage rather than vectors; optimized implementations may sit behind foreign functions. ImportC vectors are audited separately. |
| BetterC (`betterc.dd`) | Restricted | BetterC is mandatory, but its upstream documentation is not treated as a complete Laser-D specification. |
| ImportC (`importc.dd`) | Restricted | ImportC is retained. Standalone C11 compilation and mixed Laser-D/C modules are supported for the reviewed baseline; preprocessing, headers, macros, atomics, vector extensions, inline assembly, and implementation extensions remain to be audited. |
| Live functions (`ob.dd`) | Rejected | `@live` annotations and implicit live ownership/borrowing analysis are not part of Laser-D. Ownership conventions are explicit and documented but are not compiler-proven. |
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

## Attribute decisions

| Feature | Status | Decision | Tests |
| --- | --- | --- | --- |
| User-defined attributes | Rejected | `@(ArgumentList)`, `@identifier`, UDA template instances, and UDA call expressions are rejected in every D source location, including modules, declarations, functions, parameters, aggregate members, and enum members. | `user_defined_attributes_rejected.d`, `module_user_defined_attribute_rejected.d` |
| Function safety attributes | Restricted | `@safe` and `@trusted` are rejected. `@system` is mandatory and implicit, so spelling it explicitly is also rejected. | `implicit_function_attributes.d`, `explicit_safety_attributes_rejected.d` |
| Live-function attribute | Rejected | `@live` is rejected on declarations and function types, and Laser-D never enables live ownership/borrowing analysis. | `live_attribute_rejected.d` |
| Purity and threading attributes | Rejected | `pure`, `shared`, `__gshared`, and `synchronized` are rejected. | `threading_and_purity_rejected.d`, `gshared_rejected.d` |
| Remaining built-in attributes | Undecided | Built-in attributes other than the decided function-safety, `nothrow`, `@nogc`, and `@live` groups retain their individual classifications. | Existing attribute-specific tests |
| ImportC implementation attributes | Restricted | C and GNU attributes parsed from ImportC input are not D UDAs and remain part of the ImportC audit. | `importc_upstream_compilable_cattributes.i` |

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
| Struct methods and constructors | Supported | Runtime-free methods and ordinary constructors are supported and generated helper functions inherit Laser-D's implicit function attributes. | `aggregate_types_accepted.d`; upstream `struct_allMembers.d` used as differential evidence |
| Struct destructors | Rejected | Source-level struct destructors are rejected; Laser-D does not schedule user-defined implicit work at struct scope exit. | `struct_destructor_rejected.d` |
| Struct postblits | Rejected | Source-level `this(this)` postblit constructors are rejected; ordinary struct copying does not invoke a user-defined post-copy hook. | `struct_postblit_rejected.d` |
| Aggregate invariants | Rejected | `invariant` declarations are not part of Laser-D. Programs must use explicitly called validation functions when they require consistency checks. | `invariant_rejected.d` |
| Alias this | Rejected | Both `alias member this` and `alias this = member` declarations are rejected. Laser-D does not perform implicit member forwarding or conversion through `alias this`. | `alias_this_rejected.d` |
| Bit fields | Supported | Integral signed and unsigned bit fields, default initializers, anonymous and zero-width alignment fields, struct and union storage, access, assignment, and bit-field traits are supported without a preview switch. Layout remains implementation-defined and must not be assumed portable without target-specific verification. | `bitfields_accepted.d`; upstream `dbitfields.d` used as differential evidence |
| Invalid bit fields | Rejected | Non-integral fields, widths larger than their storage type, and named zero-width fields are rejected. | `bitfield_non_integral_rejected.d`, `bitfield_width_rejected.d`, `bitfield_named_zero_width_rejected.d` |
| Struct copy and move constructors | Rejected | User-defined copy and move constructors are rejected. Ordinary value-copyable structs retain field-wise copying without post-copy or ownership hooks. | `copy_move_constructors_rejected.d` |
| Nested structs | Restricted | Local structs are supported when they need no hidden context. A struct requiring an enclosing-function or aggregate context pointer is rejected. | `context_free_local_struct_accepted.d`, `hidden_context_struct_rejected.d` |
| Constructor delegation | Rejected | A struct constructor cannot invoke another constructor with `this(...)`; constructors initialize their fields directly. | `constructor_delegation_rejected.d` |
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
| COM classes and interfaces | Rejected | Declaration of the magic `IUnknown` interface is rejected, preventing the frontend from creating the COM root from which COM interface and class behavior is inherited. | `com_interface_rejected.d` |
| Objective-C object model and linkage | Rejected | `extern(Objective-C)` is rejected for all declarations, excluding Objective-C classes, protocols, methods, and standalone functions. `D_ObjectiveC` is never predefined. | `objective_c_linkage_rejected.d`, `objective_c_version_absent.d` |
| C++ classes and interfaces | Rejected | Class and interface declarations under C++ linkage are rejected, including forward declarations, definitions, templates, and explicit class/struct mangling forms. | `cpp_class_rejected.d`, `cpp_interface_rejected.d` |
| C++ free functions | Supported | `extern(C++)` free-function declarations, function types, mangling, and overload sets remain available without enabling the C++ object model. | `cpp_free_functions_accepted.d` |
| C++ structs | Rejected | Struct declarations under C++ linkage are rejected, including forward declarations, definitions, templates, and explicit class-mangling forms. | `cpp_struct_rejected.d` |

## Module decisions

| Feature | Status | Decision | Tests |
| --- | --- | --- | --- |
| Module declarations and namespaces | Supported | A source file may declare one named module, or omit the declaration and use its file name. Module contents occupy their module namespace and `__MODULE__` reports the declared name. | `modules_accepted.d`, `extra-files/module_basic.d`, `extra-files/module_implicit.d` |
| Module imports | Supported | Ordinary, aliased, selective, renamed, static, duplicate, private, and public imports are supported. Static imports require qualification; public imports re-export symbols while private imports do not. | `modules_accepted.d`, `module_private_import_rejected.d` |
| Import cycles | Supported | Mutually importing modules are supported. An import cycle does not change import visibility or implicitly re-export symbols. | `modules_accepted.d`, `extra-files/module_cycle_a.d`, `extra-files/module_cycle_b.d` |
| Separate compilation | Supported | Modules may be compiled into separate object files while resolving declarations through their imported source interfaces. | `modules_accepted.d` |
| Missing modules | Rejected | Importing a module that cannot be resolved on the configured import paths is diagnosed. | `module_missing_import_rejected.d` |
| Module runtime metadata | Rejected | Laser-D never generates `ModuleInfo` instances and does not expose the Druntime `ModuleInfo` type. Ordinary module namespaces and separate compilation do not require this metadata. | `runtime_metadata_absent.d`, `modules_accepted.d` |
| Module lifecycle | Rejected | `static this()`, `static ~this()`, and their shared forms are rejected, including lifecycle declarations nested in aggregates or templates. | `module_lifecycle_rejected.d`; shared forms also covered by threading rejection tests |
| Packages and advanced module facilities | Undecided | Package modules, package visibility, module deprecation, and edition-qualified modules require separate review. Module UDAs are rejected by the cross-cutting UDA decision. | `module_user_defined_attribute_rejected.d` |

## ImportC decisions

| Feature | Status | Decision | Tests |
| --- | --- | --- | --- |
| Standalone ImportC | Supported | Preprocessed C translation units can be compiled, linked, and executed directly. The reviewed C11 baseline includes functions, local and aggregate initialization, structs, unions, enums, function pointers, and static assertions. | `importc_standalone.i` |
| Importing C modules | Supported | A Laser-D module can import declarations from a preprocessed C translation unit compiled in the same invocation and can call its functions and access its globals and value types. | `importc_module_accepted.d`, `extra-files/importc_api.i` |
| ImportC scalar representation | Supported | C source retains the C types needed by ImportC. In particular, C `long double` remains available through the frontend's internal extended representation even though Laser-D source cannot name D `real`. | `importc_module_accepted.d` |
| Upstream preprocessed ImportC compatibility | Restricted | The 41 upstream `.i` tests that currently pass under Laser-D are copied into the Laser-D suite. Two upstream tests requiring `__importc_builtins.di` remain blocked by its use of rejected D `real`; the generated-interface golden test requires a Laser-D-specific expected output. | `importc_upstream_*.i` |
| ImportC preprocessing and extended surface | Undecided | Automatic preprocessing, headers, macros, conditional compilation, atomics, vector extensions, inline assembly, and implementation-specific extensions require separate review. | None |

## Expression decisions

| Feature | Status | Decision | Tests |
| --- | --- | --- | --- |
| Primary scalar expressions | Supported | Identifiers, parentheses, `null`, Boolean literals, supported integer, floating-point, and character literals, and construction or conversion with supported scalar types are retained. | `primary_scalar_expressions_accepted.d` |
| Rejected scalar expressions | Rejected | Literal or construction forms that introduce `real`, imaginary, or complex types remain rejected by their corresponding type decisions. | `real_rejected.d`, `imaginary_rejected.d`, `complex_rejected.d` |
| `new` expressions | Rejected | Every `new` expression is rejected, including scalar, struct, placement, class, and array forms. Laser-D requires allocation and initialization to be explicit through supported storage or C interoperability. | `new_expressions_rejected.d`, `new_array_rejected.d` |
| `super` | Rejected | Structs do not support inheritance, while classes and interfaces are rejected, so neither the expression nor its class-hierarchy use in `is` expressions has a valid meaning. | `super_rejected.d` |
| `__rvalue` | Rejected | Both `__rvalue(expression)` and the `__rvalue` function attribute are rejected. Laser-D does not expose this unchecked explicit-move and ownership hint. | `rvalue_rejected.d` |
| Runtime assertions | Rejected | Runtime `assert`, message forms, `assert(0)`, and assertions inside CTFE-capable functions are rejected. Failure requires druntime hooks and ordinary assertions have build-mode-dependent removal semantics. | `runtime_assertions_rejected.d`, `runtime_assert_release_rejected.d` |
| Static assertions | Supported | `static assert` conditions and optional compile-time messages are evaluated entirely by the compiler. ImportC retains C `_Static_assert`. | `static_assertions_accepted.d`, existing template and CTFE tests, `importc_standalone.i` |
| Interpolated expression sequences | Rejected | Double-quoted, backtick, and token-string IES forms are rejected before their hidden template, automatic-import, and internal string-mixin lowering. | `interpolated_expressions_rejected.d` |
| `this` expressions | Supported | In struct and union constructors and instance methods, `this` supports field qualification, value passing and returns, non-owning address-taking, method delegates, `typeof`, and template receiver inference. Hidden outer contexts and all separately rejected receiver operations remain unavailable. | `this_expressions_accepted.d`, `hidden_context_struct_rejected.d` |
| Primary-expression grammar | Restricted | Every primary form is classified. Root-qualified names and template instances, `$` in indexing, retained literals and properties, scalar construction, `typeof`, `is`, parentheses, special keywords, and non-capturing function literals are supported. Dynamic and associative-array literals, `typeid`, import expressions, string mixin expressions, `new`, `super`, interpolation, and forms involving rejected types follow their individual rejection decisions. | `primary_scalar_expressions_accepted.d` and the individual feature tests |

## Mixin decisions

| Feature | Status | Decision | Tests |
| --- | --- | --- | --- |
| String mixin declarations and statements | Rejected | Compile-time source-text injection in declaration and statement positions is rejected. | `string_mixin_declaration_rejected.d`, `string_mixin_statement_rejected.d` |
| String mixin expressions and types | Rejected | Source text cannot be reparsed as an expression or type. | `string_mixin_expression_rejected.d`, `string_mixin_type_rejected.d` |
| Template mixins | Supported | Mixin template declarations and template mixin instantiations remain supported. | `template_mixins_accepted.d` |

## Array decisions

| Feature | Status | Decision | Tests |
| --- | --- | --- | --- |
| Fixed-size arrays | Implementation defect | Fixed-size arrays provide inline value storage in permitted static storage, stack variables, and containing aggregates. Context-typed array literals and integral compile-time dimension expressions are intended to work without allocation, but the current frontend rejects context-typed literals and misclassifies manifest-identifier dimensions as associative-array types. | `static_arrays_and_slices_accepted.d`; positive fixed-literal and symbolic-dimension coverage needed |
| Non-owning slices | Supported | Dynamic-array slice values are retained as pointer-and-length views over separately owned storage. Slicing fixed arrays and pointer ranges, sub-slicing, indexing, mutation of mutable backing storage, `$`, `.ptr`, read-only `.length`, filling, and copying into existing compatible POD storage are supported. | `static_arrays_and_slices_accepted.d`, `strings_and_slices_accepted.d`, `string_comparison_and_slice_copy_accepted.d` |
| Strings | Restricted | UTF-8, UTF-16, and UTF-32 literals are supported as non-owning immutable character slices over compiler-provided static storage. Indexing, slicing, same-element-type equality, identity, passing, and returning are supported. Mutation, implicit conversion to mutable slices, ordered comparison, and the GC-backed array operations listed below are rejected. The conventional string type names are aliases supplied by `object.d`. | `strings_and_slices_accepted.d`, `string_comparison_and_slice_copy_accepted.d`, `string_mutation_rejected.d`, `ordered_slice_comparison_rejected.d` |
| Ordered array and slice comparison | Rejected | `<`, `<=`, `>`, and `>=` on arrays or slices are rejected because they require the D runtime `object.__cmp` hook. | `ordered_slice_comparison_rejected.d` |
| GC-backed array operations | Rejected | Dynamic array literals, concatenation, append, `.dup`, `.idup`, `.capacity`, and assignment to dynamic-array `.length` are rejected. Array allocation with `new T[n]` is covered by the rejection of every `new` expression. | `dynamic_array_literal_rejected.d`, `new_array_rejected.d`, `array_concatenation_rejected.d`, `array_gc_properties_rejected.d` |
| Associative arrays | Rejected | Associative-array types and literals are rejected. | `associative_arrays_rejected.d`, `associative_array_literal_rejected.d` |

## Function, delegate, and closure decisions

| Feature | Status | Decision | Tests |
| --- | --- | --- | --- |
| Ordinary functions and function pointers | Supported | Direct calls, taking function addresses, indirect calls, and non-capturing function literals converted to function pointers are supported. | `functions_and_function_pointers_accepted.d` |
| Delegates | Supported | Non-capturing delegate literals and delegates to struct methods are supported as context-and-function-pointer values. | `delegates_accepted.d` |
| Capturing delegates and closures | Rejected | Function and delegate literals cannot capture lexical state, regardless of whether the context is stack-scoped or would require heap allocation. Named nested functions are rejected separately. | `capturing_delegates_rejected.d` |
| Function contracts | Rejected | Expression and block `in`/`out` contracts, named postcondition results, and contract-style `do` bodies are rejected on ordinary, member, templated, constructor, and literal functions. | `function_contracts_rejected.d` |
| Named nested functions | Rejected | Capturing, context-free, and `static` named functions declared within another function are rejected. Use module-level functions or non-capturing function literals. | `named_nested_functions_rejected.d` |
| C ABI variadic functions | Supported | `extern(C)` variadic declarations, definitions, function pointers, and calls are supported for C interoperability. | `c_variadic_functions_accepted.d` |
| D runtime variadic functions | Rejected | D-style untyped variadics and typesafe runtime variadics are rejected. They require hidden TypeInfo arguments or implicit argument aggregation; lazy variadics additionally conflict with the rejection of lazy parameters and capturing delegates. Variadic template parameters remain supported. | `d_variadic_functions_rejected.d`, template acceptance tests |
| Program entry point | Restricted | Executables must explicitly define `extern(C) int main()` or `extern(C) int main(int, char**)`. D `main`, non-`int` or inferred returns, nonstandard parameter lists, `WinMain`, `DllMain`, and the generated `-main` option are rejected. ImportC retains C entry-point handling. | Existing runnable tests, `main_arguments_accepted.d`, `d_main_rejected.d`, `nonstandard_c_main_rejected.d`, `inferred_main_rejected.d`, `noreturn_main_rejected.d`, `posix_main_extension_rejected.d`, `special_entry_points_rejected.d`, `generated_main_option_rejected.d` |
| Compiler-generated function helpers | Internal | Helpers required by supported language constructs remain frontend implementation details and do not add source-level function forms. | Feature-specific acceptance tests |

## Property decisions

| Feature | Status | Decision | Tests |
| --- | --- | --- | --- |
| Common and type properties | Supported | `.init`, `.sizeof`, `.alignof`, `.stringof`, and `.mangleof` are supported for retained types and expressions. | `builtin_properties_accepted.d` |
| Numeric properties | Restricted | Integral limits and floating-point metadata for `float` and `double` are supported. Properties requiring rejected scalar types remain unavailable. The legacy floating-point `.im` property is rejected; an aggregate field named `im` remains valid. | `builtin_properties_accepted.d`, `imaginary_property_rejected.d`, scalar-type rejection tests |
| Aggregate and enum properties | Supported | Struct `.tupleof`, field `.offsetof`, layout properties, and the reviewed enum properties are supported. Class properties are unavailable with classes. | `builtin_properties_accepted.d`, `aggregate_types_accepted.d` |
| Array and slice properties | Restricted | Read-only `.length` and `.ptr` are supported. `.dup`, `.idup`, `.capacity`, and writes to dynamic-array `.length` remain rejected. | `builtin_properties_accepted.d`, `static_arrays_and_slices_accepted.d`, `array_gc_properties_rejected.d` |
| Delegate properties | Supported | `.ptr` and `.funcptr` expose the context and function pointers without runtime allocation. A non-capturing delegate has a null `.ptr`. | `builtin_properties_accepted.d` |
| User-defined property functions | Rejected | The built-in `@property` attribute is rejected on member and free functions, including getter, setter, immutable-receiver, and UFCS forms. Source-defined behavior must use explicit function-call syntax. | `property_functions_rejected.d` |
| Optional function-call parentheses | Rejected | Every source-level function, method, template, and UFCS call requires explicit parentheses. This includes functions callable with no explicit arguments because their parameters have defaults and setter-like assignment syntax. | `optional_parentheses_rejected.d`; explicit-call regressions throughout the suite |

## Operator-overloading decisions

| Feature | Status | Decision | Tests |
| --- | --- | --- | --- |
| Modern struct operators | Supported | Unary, binary, right-hand binary, equality, ordering, cast, call, assignment, compound assignment, and POD postfix operators lower to runtime-free method calls. | `operator_overloading_accepted.d` |
| Indexing and slicing hooks | Supported | Value-returning indexing, index assignment, index compound assignment, one-dimensional slicing, slice assignment, and `$` are supported. Non-owning slice results retain the normal array restrictions. | `operator_overloading_accepted.d` |
| Operator forwarding | Supported | `opDispatch` forwarding through supported templates is retained. | `operator_overloading_accepted.d` |
| Immutable receiver operators | Supported | Operators may be declared for and invoked on immutable struct values without requiring the rejected `const` qualifier. | `operator_overloading_accepted.d` |
| Cross-cutting restrictions | Restricted | Operator hooks cannot use rejected qualifiers, `ref` returns, classes, postblits, GC-backed arrays, or other rejected constructs. Index mutation uses assignment hooks rather than a reference-returning `opIndex`. | `operator_overloading_restrictions.d` and the individual feature-rejection tests |
| Legacy D1 operator hooks | Rejected | The legacy unary, binary, reverse-binary, membership, postfix, dereference, concatenation, and compound-assignment hook names are rejected on aggregate instance methods. Modern templated operator hooks provide the supported equivalents. | `legacy_d1_operators_rejected.d` |
| Multidimensional indexing | Supported | Dimension-tagged `opSlice` and `opDollar`, mixed index/slice reads, assignments, compound assignments, unary operations, and single evaluation of the container expression are supported using ordinary value descriptors and fixed storage. | `multidimensional_indexing_accepted.d` |

## Template and compile-time execution decisions

| Feature | Status | Decision | Tests |
| --- | --- | --- | --- |
| Core templates | Supported | Type, value, alias, variadic, recursive, eponymous, function, aggregate, enum, variable, and alias templates are supported and compose with the reviewed Laser-D feature set. | `templates_accepted.d`, `template_supported_features_accepted.d` |
| Selection and instantiation | Supported | Explicit instantiation, IFTI, specialization, default arguments, and constraints are supported. | `templates_accepted.d` |
| Template emission | Supported | Instances needed across separately compiled modules are emitted without requiring the D runtime. | `betterc_template_emission.d` |
| CTFE | Supported | Functions may execute at compile time for manifest constants, assertions, template arguments, initializers, and fixed-array dimensions; `__ctfe` is supported. | `ctfe_accepted.d` |
| Compile-time control flow | Supported | `static if`, `static foreach`, and `static assert` are supported. | `ctfe_accepted.d` |
| Type inspection | Supported | `typeof` is non-evaluating and supports expression and return-type queries. `is` supports validity, equivalence, conversion, category, and pattern-deduction queries over supported Laser-D types. | `type_inspection_accepted.d` |
| Existing language restrictions | Restricted | Templates and CTFE do not bypass rejected Laser-D features; string mixins remain rejected inside templates. | `template_string_mixin_rejected.d` |
| Templated struct constructors | Supported | Ordinary constructors in struct templates and templated constructors in ordinary structs are supported. Their internal in-place construction mechanism does not expose source-level `ref` returns. | `template_struct_constructors_accepted.d`, `template_supported_features_accepted.d` |

## Trait decisions

| Feature | Status | Decision | Tests |
| --- | --- | --- | --- |
| Type and value predicates | Supported | Arithmetic, integral, floating, scalar, unsigned, array-kind, overlap, copyability, POD, zero-initialization, construction, postblit, destruction, and alias-this queries are supported. Predicates for rejected type kinds remain usable by generic code, but cannot introduce those types. | `traits_type_and_function_accepted.d`, `bitfields_accepted.d` |
| Function and parameter reflection | Supported | Function kind, virtual index, return ABI, attributes, variadic style, parameter storage classes, and the current function's parameter tuple may be inspected at compile time. Class-only results have no valid Laser-D class operands. | `traits_type_and_function_accepted.d` |
| Symbol reflection | Supported | Names, membership, members, overloads, parents, protection, visibility, linkage, source location, C++ namespaces, target information, and symbol identity may be inspected. `getAttributes` remains available but source declarations cannot carry UDAs, so it returns an empty sequence for them. | `traits_symbol_accepted.d`, `bitfields_accepted.d` |
| Semantic probes | Supported | `__traits(compiles)` and `__traits(isSame)` are supported for compile-time feature detection and identity tests. | `traits_symbol_accepted.d` |
| Initialization symbol | Supported | `__traits(initSymbol)` is retained for supported aggregate types. | `traits_type_and_function_accepted.d` |
| String-to-type generation | Rejected | `__traits(toType)` is rejected because it creates a type from string/mangled text and would restore a form of compile-time text-to-language generation. | `traits_removed_operations_rejected.d` |
| GC pointer metadata | Rejected | `__traits(getPointerBitmap)` is rejected because Laser-D has no garbage collector or GC scanning metadata contract. | `traits_removed_operations_rejected.d` |
| Unit-test discovery | Rejected | `__traits(getUnitTests)` is rejected because Laser-D has no language unit-test declarations or hidden test-function discovery protocol. | `unit_test_discovery_rejected.d` |

## Compile-time I/O decisions

| Feature | Status | Decision | Tests |
| --- | --- | --- | --- |
| Compile-time file input | Rejected | Import expressions such as `import("file")` are rejected. Compilation cannot read source-selected host files through the language, regardless of `-J` paths. | `compile_time_io_rejected.d` |
| Compile-time message output | Rejected | Declaration and statement forms of `pragma(msg)` are rejected. CTFE cannot emit user-selected diagnostic output. | `compile_time_io_rejected.d`, `compile_time_statement_output_rejected.d` |
| Pure compile-time execution | Supported | CTFE over compiler-known values remains supported when it does not perform host I/O. Normal compiler diagnostics and compiler-generated artifacts are not language-level compile-time I/O. | `ctfe_accepted.d` |

## Runtime metadata decisions

| Feature | Status | Decision | Tests |
| --- | --- | --- | --- |
| `TypeInfo` | Rejected | Laser-D does not expose Druntime's `TypeInfo` hierarchy or generate runtime type descriptors. | `runtime_metadata_absent.d` |
| `typeid` expressions | Rejected | Both type and expression forms of `typeid` are rejected, including during CTFE; compile-time type inspection remains available through `typeof`, `is`, and supported `__traits`. | `typeid_rejected.d`, `runtime_metadata_absent.d` |
| `ModuleInfo` | Rejected | No runtime module descriptors are generated or exposed. This does not affect module namespace, import, or separate-compilation behavior. | `runtime_metadata_absent.d`, `modules_accepted.d` |

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
