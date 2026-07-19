// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/real_rejected.d(13): Error: type `real` is not supported in Laser-D; use `double` instead
laser-d/real_rejected.d(14): Error: `real` literals are not supported in Laser-D; use a `double` literal without the `L` suffix
laser-d/real_rejected.d(15): Error: type `real` is not supported in Laser-D; use `double` instead
laser-d/real_rejected.d(16): Error: `long double` is not supported in Laser-D; use `double` instead
---
*/

real value;
enum literal = 1.0L;
enum maximum = real.max;
long double alternateSpelling;
