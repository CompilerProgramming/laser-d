// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/basic_duplicate_declaration_rejected.d(11): Error: variable `basic_duplicate_declaration_rejected.duplicate` conflicts with variable `basic_duplicate_declaration_rejected.duplicate` at laser-d/basic_duplicate_declaration_rejected.d(10)
---
*/

int duplicate;
int duplicate;
