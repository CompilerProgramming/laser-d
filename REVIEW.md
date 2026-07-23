# Review notes

## Fixed-array initializer expressions

During the ordinary control-flow audit, `int[4] values = [1, 2, 3, 4];` was
rejected as a dynamic array literal. The arrays specification review confirmed
that context-typed literals should initialize fixed storage without allocation.
`FEATURE_STATUS.md` records the current blanket rejection as an implementation
defect. Positive conformance coverage should be added when that defect is fixed.

## Symbolic fixed-array dimensions

During the type-qualifier documentation validation, `enum n = 3; alias A =
int[n];` was rejected as an associative-array type. Literal dimensions and some
compound CTFE dimensions already work, but a manifest identifier is currently
misclassified before its value establishes a fixed-array dimension. The arrays
specification requires integral compile-time dimension expressions, so this is
an implementation defect. Positive coverage for manifest and other symbolic
dimensions should accompany the fix.
