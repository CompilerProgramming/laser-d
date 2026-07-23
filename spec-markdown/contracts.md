---
title: Function contracts
status: rejected
source: ../spec/contracts.dd
---

# Function Contracts (Excluded)

> **Laser-D normative:**
>
> Function contracts are not part of Laser-D. Functions use a
> single ordinary `{ ... }` body, and validation or error reporting must be
> written explicitly in that body or by the caller.

## <a id="rejected-syntax"></a>Rejected Syntax

> **Excluded from Laser-D:** Laser-D rejects:

- `in` preconditions in expression and block forms,
- `out` postconditions in expression and block forms,
- named postcondition result variables,
- contract-style `do` function bodies.

These forms are rejected on free functions, methods, constructors, templates, and function literals. Contract inheritance and overriding behavior
are unavailable because classes and interfaces are rejected.

## <a id="assertions"></a>Assertions

Runtime `assert` expressions are rejected independently of contracts.
Compile-time `static assert` remains supported for conditions evaluated by
the compiler.

## <a id="alternatives"></a>Explicit Validation

Preconditions should be checked with ordinary control flow and represented
through the function's documented result or an explicitly called error API.
Postconditions should likewise be checked before each successful return when
they are required.

Laser-D does not add hidden contract calls, build-mode-dependent contract
removal, exception throwing, or runtime contract hooks.

## <a id="rationale"></a>Rationale

A single function-body syntax keeps executable validation visible and
avoids a second assertion-based error path whose execution can depend on
compiler options. Explicit results also work with the no-exceptions and
no-D-runtime model.
