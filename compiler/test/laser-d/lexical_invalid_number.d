// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/lexical_invalid_number.d(10): Error: binary digit expected, not `2`
---
*/

enum invalidBinary = 0b102;
