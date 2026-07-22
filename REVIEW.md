# Review notes

## Fixed-array initializer expressions

During the ordinary control-flow audit, `int[4] values = [1, 2, 3, 4];` was
rejected as a dynamic array literal. The arrays specification review confirmed
that context-typed literals should initialize fixed storage without allocation.
`FEATURE_STATUS.md` records the current blanket rejection as an implementation
defect. Positive conformance coverage should be added when that defect is fixed.
