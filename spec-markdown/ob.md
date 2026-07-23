---
title: Live functions
status: rejected
source: ../spec/ob.dd
---

# Live Functions (Excluded)

> **Laser-D normative:**
>
> The experimental `@live` ownership and borrowing system
> is not part of Laser-D. The `@live` attribute is rejected on declarations
> and function types, and no function receives live analysis implicitly.

## <a id="rejected-attribute"></a>Rejected Attribute

> **Excluded from Laser-D:**
>
> Prefix and postfix `@live` annotations are rejected on
> free functions, methods, templates, function literals, aliases, and function
> types. Compiler switches cannot enable the feature for Laser-D source.

## <a id="no-analysis"></a>No Implicit Ownership Analysis

Laser-D does not classify pointers or references as owners, borrowers, or
scoped live values. It does not diagnose ownership escape, multiple aliases, use after move, or borrowing conflicts through the `@live` rules.

This does not create automatic memory management. The ordinary Laser-D
memory model still requires explicit storage duration, ownership conventions, and release operations.

## <a id="rationale"></a>Rationale

The live-function system is experimental and covers only selected pointer
and lifetime patterns. Laser-D avoids a feature whose guarantees depend on
partial analysis or whose behavior changes when annotations or compiler
switches are added.

## <a id="explicit-conventions"></a>Explicit Conventions

APIs should express ownership in their documented contracts and use
ordinary values, pointers, non-owning slices, and explicit create/destroy or
acquire/release functions. The compiler does not prove that these conventions
are followed.

Function parameters remain subject to the separately decided Laser-D
parameter annotations. Rejection of `@live` does not restore `scope`, `return`, or other rejected lifetime annotations.
