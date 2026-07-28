---
title: ImportC
status: restricted
review-sources: ../spec/importc.dd
---

# ImportC

ImportC is Laser-D's C-language frontend mode. It compiles reviewed,
already-preprocessed C translation units and makes their declarations
available to Laser-D modules.

ImportC source follows C rules rather than Laser-D syntax. Features awaiting
ImportC review are listed in [Feature status](../FEATURE_STATUS.md).

## Translation units

A file with the `.i` extension is treated as an already-preprocessed C
translation unit. Its module identity is derived from its filename.

The translation unit may:

- define a standalone C program;
- compile to an object for normal linking; or
- be compiled alongside a Laser-D module that imports its declarations.

The reviewed input begins after C preprocessing has produced the `.i` file.

## Reviewed C baseline

The tested C baseline includes:

- function declarations, definitions, calls, parameters, and returns;
- local variables and file-scope C storage;
- the C `int main(void)` entry point;
- structs, unions, enums, typedefs, and function pointers;
- scalar, aggregate, and local initialization;
- member access, arithmetic, comparisons, conditional expressions, and
  ordinary control flow;
- `sizeof`; and
- C11 `_Static_assert`.

These constructs retain C semantics, storage duration, namespaces, and target
representation.

## C types and representation

C declarations use the C spelling and target ABI for their types, layout, and
calling convention. ImportC retains the scalar types required to represent the
reviewed declarations.

C `long double` remains represented through the frontend's internal extended
floating-point type. A Laser-D module may import a C declaration containing
that type and inspect or pass its ABI representation.

C struct and union layout, enum representation, function types, pointers, and
file-scope storage likewise retain their C meaning.

## Standalone programs

A preprocessed translation unit may define `main`, compile, link, and execute
without a Laser-D root module.

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
    struct Pair pair = { 20, 22 };
    return pair.first + pair.second == 42 ? 0 : 1;
}
```

The program uses C entry-point and linkage rules.

## Importing C declarations

A Laser-D module may import an ImportC translation unit compiled in the same
invocation:

```d
import c_api;

extern(C) int main()
{
    CPoint point = make_point(20, 22);
    return sum_point(point) == 42 ? 0 : 1;
}
```

The imported interface may contain C functions, globals, structs, unions,
enums, typedefs, and function pointers.

- Functions retain C linkage and their C calling convention.
- Structs and unions retain target C layout.
- Enum constants and typedef names are visible through the imported module.
- A C global denotes storage defined under the C translation unit's rules.

Importing declarations does not replace the need to compile and link the
translation unit that supplies their definitions.

## Static assertions

`_Static_assert` evaluates its condition during compilation and emits no
runtime code:

```c
_Static_assert(sizeof(unsigned long) >= sizeof(unsigned int),
               "unexpected integer representation");
```

## Source-language boundary

Laser-D and ImportC share semantic and backend infrastructure but retain
separate parsers and source-language rules.

- A `.d` file follows the Laser-D specification.
- A `.i` file follows the reviewed C baseline.
- Declarations cross the boundary through their compiled type representation
  and ABI.

Frontend reuse does not combine both source languages within a translation
unit.

## Regression evidence

The Laser-D conformance suite includes copies of 41 upstream preprocessed
ImportC tests that currently pass. They include compilable, runnable, and
expected-failure cases.

Each copied test guarantees only the behavior it exercises that is consistent
with the decisions in [Feature status](../FEATURE_STATUS.md). The focused
`importc_standalone.i` and mixed `importc_module_accepted.d` tests define the
reviewed baseline more directly.

## Portability and ABI

ImportC uses the selected target's C ABI. Type sizes, alignment, calling
conventions, enum representation, and `long double` representation may differ
between Windows, Linux, and macOS.

Cross-platform interfaces should use C declarations whose representation and
calling convention are defined for every intended target.

## Conformance testing

A baseline test supplies preprocessed `.i` input. A mixed-language test
compiles its Laser-D and ImportC sources together and links and runs the result
when behavior depends on calls, storage, or layout.

An expected-failure test must demonstrate the intended C or cross-language
diagnostic rather than an incidental restriction from the Laser-D parser.
