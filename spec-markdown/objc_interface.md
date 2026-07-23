---
title: Objective-C interoperability
status: rejected
source: ../spec/objc_interface.dd
---

# Objective-C Interoperability (Excluded)

> **Laser-D normative:**
>
> Objective-C interoperability is not part of Laser-D.
> `extern(Objective-C)` linkage is rejected on every declaration, independent
> of the compiler target or backend capabilities.

## <a id="rejected-surface"></a>Rejected Surface

> **Excluded from Laser-D:** Laser-D source cannot declare Objective-C:

- classes, categories, or class extensions,
- protocols or protocol conformance,
- instance variables, properties, selectors, or methods,
- standalone functions with Objective-C linkage,
- message dispatch, class references, or protocol references.

The rejection applies before the declaration is lowered to an
Objective-C ABI. No Objective-C name mangling, method family inference, ownership convention, exception convention, or runtime metadata is provided.

## <a id="predefined-version"></a>Predefined Version

The predefined version identifier `D_ObjectiveC` is never defined for
Laser-D source. Targeting a platform with an Objective-C runtime does not
change the Laser-D language surface.

## <a id="rationale"></a>Rationale

Objective-C interoperability introduces a separate object model, dynamic
message dispatch, runtime metadata, ownership conventions, target-specific
linking, and compiler-specific ABI behavior. Laser-D excludes classes and
interfaces generally and does not expose this additional object system.

## <a id="alternatives"></a>C Interface Alternative

An Objective-C implementation may expose a C-callable wrapper using opaque
pointers and explicit functions. Laser-D can declare that C interface without
understanding Objective-C objects, selectors, or ownership rules.

```d
struct ForeignObject;

extern(C):
ForeignObject* foreign_object_create();
int foreign_object_apply(ForeignObject* object, int value);
void foreign_object_destroy(ForeignObject* object);
```

The wrapper contract defines allocation, lifetime, nullability, thread-affinity, and error handling. These are not inferred by Laser-D.

## <a id="importc"></a>ImportC

ImportC retains its separately reviewed C declaration rules. Importing a C
wrapper header does not enable Objective-C syntax or linkage in Laser-D source.
