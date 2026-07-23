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

## ImportC variadic declarations

The variadic-function audit confirmed Laser-D-authored `extern(C)` variadic
definitions, function pointers, and calls. Adding a variadic prototype to the
minimal ImportC fixture, however, made ImportC request
`__importc_builtins.d`; that module is not present on the fixture's configured
import paths. The prototype was therefore removed from this change rather than
masking the dependency with a test-only stub. ImportC variadic declarations
need dedicated coverage when the minimal ImportC environment provides the
compiler's builtins module.
