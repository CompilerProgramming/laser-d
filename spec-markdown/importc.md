---
title: ImportC
status: restricted
source: ../spec/importc.dd
---

# ImportC

> **Laser-D normative:**
>
> ImportC is retained as a distinct C-language frontend mode.
> Laser-D guarantees a reviewed baseline for already-preprocessed C translation
> units and for importing their declarations into Laser-D modules.

ImportC source is C, not Laser-D. A restriction on Laser-D syntax does not
automatically remove the corresponding C construct when that construct is part
of the reviewed ImportC baseline. Conversely, acceptance by the upstream
ImportC implementation does not make an unaudited C extension a Laser-D
guarantee.

> **Laser-D normative:**
>
> ImportC does not admit D declarations, expressions, statements, templates, attributes, or type syntax into C source. The shared
> frontend representation and semantic machinery are implementation details, not
> a mechanism for mixing the two source languages within one translation unit.

## <a id="relationship"></a>Relationship to Laser-D

Laser-D and ImportC share the compiler frontend, optimizer, backend, object
format, and linker interface, but use different parsers and source-language
rules.

- Laser-D source follows the reduced language specified by these chapters.
- ImportC source follows the reviewed C rules in this chapter.
- Declarations crossing the boundary use their compiled ABI and representation; they are not translated into unrestricted D declarations.

BetterC and ImportC are different concepts. BetterC is permanently active
for Laser-D source. ImportC parses C translation units. Both avoid depending on
the D runtime, and both may call the available C runtime through explicit
declarations.

## <a id="input"></a>Input and Translation Units

> **Laser-D normative:**
>
> A file with the `.i` extension is treated as an
> already-preprocessed C translation unit. The reviewed baseline does not depend
> on the compiler invoking an external preprocessor.

A translation unit receives a module identity derived from its filename.
It may be compiled as a standalone C program or supplied alongside a Laser-D
module that imports it.

Source inclusion, macro expansion, conditional preprocessing, and
preprocessor command-line selection occur before the reviewed `.i` input
reaches ImportC. Those facilities are not specified by the baseline.

## <a id="baseline"></a>Reviewed C Baseline

> **Laser-D normative:** The tested standalone baseline includes:

- C function declarations, definitions, calls, parameters, local variables, and returns,
- the ordinary C `int main(void)` entry point,
- file-scope variables and C static storage,
- C structs, unions, enums, typedefs, and function pointers,
- scalar, aggregate, and local initialization,
- member access, arithmetic, comparisons, conditional expressions, and ordinary control flow,
- C11 `_Static_assert` and `sizeof`.

These constructs use C semantics in an ImportC translation unit. For
example, C file-scope mutable storage remains available even though
Laser-D-owned mutable global or static storage is rejected.

## <a id="types"></a>C Types and Representation

ImportC retains the C types required to represent reviewed C declarations.
The C spelling and target ABI govern their layout.

In particular, C `long double` remains representable through the
frontend's internal extended floating-point type even though Laser-D source
cannot name D `real`. Importing such a declaration permits compile-time
layout inspection and ABI-compatible access; it does not add `real` to the
Laser-D type grammar.

The same separation applies generally to C qualifiers, storage duration, tag namespaces, declarations, and initializers. ImportC acceptance does not
authorize the corresponding rejected D syntax in a `.d` file.

## <a id="standalone"></a>Standalone ImportC Programs

A preprocessed translation unit may define `main`, compile to an object, link through the normal compiler driver, and execute without a Laser-D root
module.

```c
struct Pair
{
    int first;
    int second;
};

_Static_assert(sizeof(struct Pair) == 2 * sizeof(int),
               "unexpected layout");

int main(void)
{
    struct Pair pair = { 20
22 };
    return pair.first + pair.second == 42 ? 0 : 1;
}
```

The program uses the C entry-point and C linkage rules. Laser-D's explicit
`extern(C) int main(...)` requirement applies to a Laser-D root module, not
to an ImportC translation unit.

## <a id="importing"></a>Importing C into Laser-D

> **Laser-D normative:**
>
> A Laser-D module may import an ImportC module compiled in the
> same invocation. Its visible C functions, globals, structs, unions, enums, typedefs, and function-pointer declarations may be used when their resulting
> interface is representable by supported frontend/backend types.

```d
import c_api;

extern(C) int main()
{
    CPoint point = make_point(20, 22);
    return sum_point(point) == 42 ? 0 : 1;
}
```

Imported C function declarations retain C linkage. C struct and union
layout follows the target C ABI. Access to a C global refers to storage owned
under the C translation unit's rules and does not create a Laser-D global
declaration.

Separate compilation and linking remain subject to ordinary symbol
visibility, object format, and ABI compatibility. Importing a module provides
declarations; it does not automatically provide a separately omitted object
definition.

## <a id="static-assertions"></a>Static Assertions

ImportC `_Static_assert` is retained and evaluated by the compiler.
This is distinct from Laser-D's `static assert` syntax. Neither form
requires a runtime assertion hook.

## <a id="source-boundary"></a>Source-Language Boundary

Laser-D-only rejection diagnostics are gated away from ImportC when the C
construct is part of the retained C model. Important examples include C
file-scope variables, C qualifiers, and C `long double`.

This boundary is deliberate but not unlimited. A C construct belongs to
the Laser-D ImportC contract only when this specification and conformance tests
classify it. Sharing an internal AST representation with D is an implementation
detail, not a source-language promise.

The frontend may internally evaluate C declarations or expressions while
performing semantic analysis. Reuse of CTFE machinery does not expose D CTFE
syntax, `__ctfe`, templates, traits, static control flow, or other D
compile-time features to ImportC source.

## <a id="upstream-tests"></a>Upstream Compatibility Evidence

The Laser-D suite contains copies of 41 upstream preprocessed ImportC tests
that currently pass: compilable, runnable, and expected-failure cases. They
provide differential regression evidence for the frontend behavior exercised
by those files.

Their presence is not a blanket guarantee for every extension appearing in
upstream ImportC. A copied test guarantees the behavior it checks only to the
extent that behavior is consistent with the decisions recorded in the
Laser-D feature inventory.

Two upstream tests that import `__importc_builtins.di` remain blocked
because that D interface uses the rejected `real` type. The generated
interface golden test also requires a Laser-D-specific expected result. These
known gaps are not silently treated as passing conformance.

## <a id="preprocessing"></a>Preprocessing (Under Review)

> **Under review:**
>
> Automatic preprocessing of `.c` and `.h` input is
> not yet a Laser-D guarantee. This includes external preprocessor discovery, command-line forwarding, include search, predefined macros, macro-to-D
> translation, and platform-specific driver behavior.

Projects requiring the current reviewed baseline should provide
preprocessed `.i` files explicitly.

## <a id="extensions"></a>C Extensions (Under Review)

The intended extension policy is C11 plus a small set of individually
reviewed GNU-compatible C extensions needed for practical interoperability.
No GNU, Clang, Microsoft, Digital Mars, or ImportC-specific extension family is
accepted wholesale.

> **Under review:** The following C and toolchain areas require separate, feature-specific review before any individual extension becomes normative:

- headers, macros, conditional preprocessing, and preprocessing pragmas,
- C atomics and memory-ordering facilities,
- vector types and compiler vector extensions,
- basic or extended inline assembly,
- GNU-compatible attributes, declarations, builtins, and calling-convention extensions beyond individually reviewed cases,
- Clang, Microsoft, and Digital Mars vendor extensions,
- implementation-specific builtins and the generated ImportC builtin interface.

Current acceptance of an item in this list is implementation behavior, not
normative Laser-D support. Current rejection likewise does not settle the final
decision until the feature is audited.

ImportC-specific syntax for importing D modules, generating D interfaces, or otherwise exposing D language facilities to C source is outside the C11 and
GNU-compatible extension policy and is not part of the reviewed baseline.

## <a id="portability"></a>Portability and ABI

Reviewed ImportC code uses the selected target's C ABI. Sizes, alignment, calling conventions, enum representation, and `long double` representation
may differ between Windows, Linux, and macOS.

Portable source should use C types and interfaces whose intended ABI is
available on every target in scope. The shared backend does not make
target-specific C extensions portable.

## <a id="diagnostics"></a>Diagnostics and Conformance

A positive conformance test should use `.i` input when preprocessing is
not the feature under review. A mixed-language test should compile the
Laser-D and ImportC sources together and, where behavior depends on linkage or
layout, link and run the result.

Expected-failure tests should demonstrate that ImportC diagnoses the
intended C error or that a cross-language declaration is unavailable for the
intended reason. Tests must not rely on an unrelated Laser-D restriction being
incorrectly applied to C source.
