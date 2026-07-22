# Review notes

## Fixed-array initializer expressions

During the ordinary control-flow audit, `int[4] values = [1, 2, 3, 4];` was
rejected as a dynamic array literal. `FEATURE_STATUS.md` currently says that
compile-time array initializers for statically allocated fixed arrays are
supported. The arrays audit should decide whether context-typed fixed-array
literal initialization is intended to work or whether that status text should
be narrowed. The control-flow test uses element assignments so this unrelated
question does not block the statement review.
