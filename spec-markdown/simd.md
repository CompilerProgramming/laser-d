---
title: Vector extensions
status: rejected
source: ../spec/simd.dd
---

# Vector Extensions (Excluded)

> **Laser-D normative:**
>
> D vector types and compiler SIMD intrinsics are not part of
> Laser-D source. Their syntax is recognized only far enough to issue a Laser-D
> diagnostic.

## <a id="rejected-surface"></a>Rejected Surface

> **Excluded from Laser-D:** Laser-D rejects:

- the `__vector` type constructor and every vector type,
- `__simd`, `__simd_sto`, and `__simd_ib` intrinsics,
- vector literals, casts, properties, indexing, and operations because no vector operand type can be formed.

## <a id="predefined-versions"></a>Predefined Versions

The predefined version identifiers `D_SIMD`, `D_AVX`, and
`D_AVX2` are never defined for Laser-D source. Their absence is a language
decision and does not report the capabilities of the target CPU.

## <a id="arrays"></a>Fixed Arrays Are Not Vectors

Fixed-size arrays remain supported as inline value storage. They do not
acquire SIMD arithmetic, vector ABI, special alignment, or target-instruction
semantics. Element operations must be written explicitly or provided by
supported struct methods and operators.

## <a id="rationale"></a>Rationale

D vector types expose target-dependent element sets, widths, alignment, calling conventions, instruction availability, and compiler intrinsics.
Portable behavior can depend on CPU features and backend lowering choices that
are outside Laser-D's reduced language contract.

## <a id="alternatives"></a>External Vector Implementation

Optimized vector code may live behind an explicit C-compatible function
boundary, with separate implementations selected by the external build or
library. Laser-D sees only the declared scalar, pointer, or fixed-storage ABI.

ImportC vector extensions remain a separate part of the ImportC audit.
Their presence in C input does not enable vector syntax in Laser-D source.
