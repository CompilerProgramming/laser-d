// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/lexical_invalid_escape.d(10): Error: escape hex sequence has 1 hex digits instead of 2
---
*/

enum invalidEscape = "\x1";
