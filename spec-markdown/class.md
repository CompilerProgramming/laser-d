---
title: Classes
status: rejected
source: ../spec/class.dd
---

# Classes (Excluded)

> **Laser-D normative:**
>
> Classes are not part of Laser-D. The frontend recognizes
> class syntax only to issue a Laser-D diagnostic; no class declaration creates
> a type or enters semantic analysis of the D object model.

## <a id="rejected-declarations"></a>Rejected Class Declarations

> **Excluded from Laser-D:**
>
> The rejection applies to every class declaration in Laser-D
> source, including:

- forward declarations and definitions,
- plain and explicit `extern(D)` classes,
- templated and nested classes,
- anonymous class expressions,
- COM classes and the magic `IUnknown` object-model root,
- classes declared with `extern(Objective-C)` linkage,
- classes declared with `extern(C++)` linkage, including `extern(C++, class)` and `extern(C++, struct)` mangling forms.

Rejecting a declaration before its body is analyzed does not make any
members, aliases, templates, or nested declarations inside that class
available to Laser-D source.

## <a id="unavailable-model"></a>Unavailable Object Model

> **Excluded from Laser-D:** Because class types do not exist, Laser-D has no:

- root `Object` class or class references,
- inheritance, base classes, overriding, or virtual dispatch,
- class virtual tables, interface tables, or monitor fields,
- class constructors, destructors, finalizers, or allocators,
- `ClassInfo`, class `TypeInfo`, or runtime class metadata,
- dynamic class casts or class identity comparisons,
- `super`, `synchronized` object monitors, or class invariants,
- class-specific properties such as `.classinfo`,
- class-only attributes such as `abstract`, `override`, or class-member `final`.

These facilities are unavailable rather than merely restricted to
BetterC-compatible cases. Their semantics depend on an object model, runtime
metadata, allocation conventions, or ABI rules that Laser-D deliberately does
not provide.

## <a id="allocation"></a>Allocation

Every `new` expression is rejected independently of the class decision.
Laser-D therefore has neither implicit class allocation nor placement
construction. Explicit foreign allocation functions may return opaque handles, but those handles are pointers governed by the foreign API, not Laser-D class
references.

## <a id="value-types"></a>Struct Alternatives

Supported structs and unions provide named value types with inline storage, fields, methods, direct field-initializing constructors, and modern operator
overloading. They have no inheritance, hidden virtual table, runtime type
identity, implicit allocation, destructor, or finalizer.

Composition and explicit function calls should be used where a program
would otherwise use inheritance or virtual methods. Function pointers and
non-capturing delegates may provide explicit dispatch when required.

## <a id="foreign-objects"></a>Foreign Object Handles

A C or other supported foreign interface may expose an object as an opaque
pointer and a set of explicitly declared functions. Laser-D does not infer
ownership, method dispatch, layout, or destruction rules for such a handle.

```d
struct ForeignHandle;

extern(C):
ForeignHandle* foreign_create();
void foreign_operate(ForeignHandle* handle);
void foreign_destroy(ForeignHandle* handle);
```

The foreign API defines whether a handle may be null, how long it remains
valid, whether operations are thread-safe, and which function releases it.
This C-style interface does not enable D, COM, Objective-C, or C++ classes in
Laser-D source.

## <a id="importc"></a>ImportC

ImportC input retains its separately reviewed C type and declaration
rules. A C structure parsed from ImportC is not a Laser-D class and does not
introduce inheritance or virtual dispatch.
