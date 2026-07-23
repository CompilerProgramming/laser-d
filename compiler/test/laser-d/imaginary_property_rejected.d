// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/imaginary_property_rejected.d(11): Error: floating-point property `.im` is not supported in Laser-D
laser-d/imaginary_property_rejected.d(12): Error: floating-point property `.im` is not supported in Laser-D
---
*/

enum floatImaginaryPart = (1.5f).im;
enum doubleImaginaryPart = (2.5).im;
