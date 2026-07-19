// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/imaginary_rejected.d(13): Error: imaginary type `ifloat` is not supported in Laser-D
laser-d/imaginary_rejected.d(14): Error: imaginary type `idouble` is not supported in Laser-D
laser-d/imaginary_rejected.d(15): Error: imaginary type `ireal` is not supported in Laser-D
laser-d/imaginary_rejected.d(16): Error: imaginary literals are not supported in Laser-D
---
*/

ifloat floatValue;
idouble doubleValue;
ireal extendedValue;
enum imaginaryLiteral = 1.0i;
