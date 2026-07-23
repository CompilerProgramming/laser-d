---
title: Interpolated expression sequences
status: rejected
source: ../spec/istring.dd
---

# Interpolation Expression Sequences

> **Laser-D:**
>
> Laser-D does not support interpolation expression sequences.
> Their string-like spelling does not construct a string and hides template, automatic-import, and source-reparsing machinery.

## <a id="syntax"></a>Rejected Syntax

> **Rejected in Laser-D:**
>
> All interpolation expression sequence forms are rejected:
>
>
>
> ```d
> i"value: $(value)"
> ivalue: $(value)
> iq{value: $(value)}
> ```
>
>
>
> The lexer recognizes these forms so that the compiler can issue a precise
> Laser-D diagnostic. No interpolation expression reaches semantic lowering.

## <a id="rationale"></a>Rationale

In D, an interpolation expression sequence lowers to several expressions:
header and footer sentinels, template-instantiated metadata for literal and
expression segments, and the embedded values themselves. The result is a
tuple-like sequence rather than a character string.

The lowering also automatically imports `core.interpolation` and
reparses the stored source text of each embedded expression through an internal
string-mixin node. Laser-D rejects this hidden text-to-language boundary along
with source-level string mixins. Converting the sequence to text additionally
requires a formatting implementation and may allocate.

## <a id="alternatives"></a>Explicit Alternatives

Programs use ordinary immutable string literals and pass values explicitly
to a formatting or output function. A variadic template API may remain
available when its arguments are written explicitly at the call site; the
rejection applies to interpolation-expression syntax and its implicit
lowering.
