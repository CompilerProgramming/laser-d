// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/cent_ucent_rejected.d(13): Error: type `cent` is not supported in Laser-D
laser-d/cent_ucent_rejected.d(14): Error: type `ucent` is not supported in Laser-D
laser-d/cent_ucent_rejected.d(15): Error: type `cent` is not supported in Laser-D
laser-d/cent_ucent_rejected.d(16): Error: type `ucent` is not supported in Laser-D
---
*/

cent signedValue;
ucent unsignedValue;
enum signedMaximum = cent.max;
enum unsignedMaximum = ucent.max;
