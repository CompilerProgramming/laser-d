---
title: Interfaces
status: rejected
source: ../spec/interface.dd
---

# Interfaces (Excluded)

> **Laser-D normative:**
>
> Interfaces are not part of Laser-D. The frontend recognizes
> interface syntax only to issue a Laser-D diagnostic; an interface declaration
> does not create a type, contract, method table, or conversion relationship.

## <a id="rejected-declarations"></a>Rejected Interface Declarations

> **Excluded from Laser-D:**
>
> The rejection applies to every interface declaration in
> Laser-D source, including:

- forward declarations and definitions,
- plain and explicit `extern(D)` interfaces,
- templated and nested interfaces,
- interfaces with base-interface lists,
- the magic COM `IUnknown` root and interfaces derived from it,
- Objective-C protocols expressed through `extern(Objective-C)` linkage,
- interfaces declared with `extern(C++)` linkage, including explicit C++ class-mangling forms.

Rejecting an interface declaration before its body is analyzed does not
make any methods, aliases, templates, or nested declarations within the body
available to Laser-D source.

## <a id="unavailable-model"></a>Unavailable Interface Model

> **Excluded from Laser-D:** Because interface types do not exist, Laser-D has no:

- interface inheritance or implementation declarations,
- implicit conversion from a value to an interface reference,
- interface references, virtual method tables, or adjustment thunks,
- runtime interface discovery, querying, downcasts, or upcasts,
- COM reference-counting conventions derived from `IUnknown`,
- Objective-C protocol dispatch,
- C++ abstract-class ABI compatibility,
- interface `TypeInfo`, identity comparisons, or class recovery.

BetterC mode alone does not define a portable, runtime-free interface
subset. Interface representation and dispatch depend on the selected object
model and ABI, while D interface conversions and metadata also depend on
facilities excluded from Laser-D.

## <a id="structural-protocols"></a>Explicit Structural Protocols

A supported language feature may validate a documented set of ordinary
struct methods without creating an interface type. Range iteration is the
principal example: the compiler checks the required range operations on the
concrete value and lowers the loop to explicit method calls.

Such validation is feature-specific and structural. It does not create a
common reference type, virtual dispatch, implicit conversion, or runtime
interface query.

## <a id="explicit-dispatch"></a>Explicit Dispatch

Programs that require runtime-selected behavior may represent it explicitly
with a context pointer and function pointers. The layout and ownership are then
ordinary program data rather than a hidden language interface.

```d
struct Operations
{
    extern(C) int function(void* context, int value) apply;
}

struct OperationHandle
{
    void* context;
    Operations* operations;
}

int invoke(ref OperationHandle handle, int value)
{
    return handle.operations.apply(handle.context, value);
}
```

The program is responsible for ensuring that the context, operation table, and selected functions remain valid. Laser-D does not add null checking, lifetime management, synchronization, or ownership transfer.

## <a id="foreign-interfaces"></a>Foreign Interfaces

Foreign object systems may be accessed through an explicitly declared
C-style API using opaque pointers and free functions. Declaring such functions
does not enable D, COM, Objective-C, or C++ interface syntax or ABI lowering.

ImportC input retains its separately reviewed C declaration rules. A C
structure containing function pointers remains a C data layout, not a
Laser-D interface.
