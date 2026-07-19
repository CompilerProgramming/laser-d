// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/complex_rejected.d(12): Error: complex type `cfloat` is not supported in Laser-D
laser-d/complex_rejected.d(13): Error: complex type `cdouble` is not supported in Laser-D
laser-d/complex_rejected.d(14): Error: complex type `creal` is not supported in Laser-D
---
*/

cfloat floatValue;
cdouble doubleValue;
creal extendedValue;
