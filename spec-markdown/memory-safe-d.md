---
title: Memory safety
status: rejected
source: ../spec/memory-safe-d.dd
---

# Checked Memory Safety (Excluded)

> **Laser-D normative:**
>
> D's compiler-checked memory-safe subset is not part of
> Laser-D. Every function and function type is implicitly `@system`, while
> explicit `@system`, `@safe`, and `@trusted` annotations are rejected.

## <a id="function-model"></a>Fixed Function Model

Safety inference is disabled. A function does not become `@safe`
because its current body happens to use only operations accepted by D's safety
checker, and a template instance does not infer a different safety mode from
its arguments.

> **Excluded from Laser-D:**
>
> The rejected syntax includes prefix and postfix safety
> attributes on functions and methods, attributes on function literals and
> templates, and safety attributes in function types or aliases.

## <a id="no-trusted-boundary"></a>No Trusted Boundary

`@trusted` cannot be used to assert that an unchecked implementation
satisfies a safe interface. Laser-D has one explicit systems-programming model
rather than separate safe, trusted, and system regions.

## <a id="consequences"></a>Programmer Responsibility

Laser-D permits supported pointer arithmetic, casts, address-taking, manual storage management, and foreign calls without claiming compiler-proven
memory safety. The programmer and foreign API contracts are responsible for
bounds, alignment, initialization, aliasing, lifetime, ownership, and valid
deallocation.

This decision does not weaken ordinary type checking or other Laser-D
restrictions. Rejected classes, GC operations, lifetime annotations, runtime
metadata, and language concurrency features remain rejected independently.

## <a id="rationale"></a>Rationale

A partially retained safety system would make guarantees depend on
inference, transitive call graphs, templates, library annotations, and trusted
escape hatches. Laser-D instead makes the absence of checked safety uniform and
visible at the language level.

## <a id="alternatives"></a>External Validation

Projects may apply code review, static analysis, sanitizers, restricted
coding standards, or verified foreign components. Those tools and policies are
outside the Laser-D language contract.
