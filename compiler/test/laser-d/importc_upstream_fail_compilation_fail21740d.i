/*
TEST_OUTPUT:
---
laser-d/importc_upstream_fail_compilation_fail21740d.i(12): Error: Bidirectional control characters in universal character names are disallowed for security reasons
laser-d/importc_upstream_fail_compilation_fail21740d.i(13): Error: Bidirectional control characters in universal character names are disallowed for security reasons
laser-d/importc_upstream_fail_compilation_fail21740d.i(14): Error: Bidirectional control characters in universal character names are disallowed for security reasons
laser-d/importc_upstream_fail_compilation_fail21740d.i(14): Error: character 0x200e is not allowed as a start character in an identifier
laser-d/importc_upstream_fail_compilation_fail21740d.i(15): Error: Bidirectional control characters in universal character names are disallowed for security reasons
laser-d/importc_upstream_fail_compilation_fail21740d.i(16): Error: Bidirectional control characters in universal character names are disallowed for security reasons
---
*/
int \u061c;
int \u061C;
int \u200e;
int \u202a;
int \u2066;
// TEST_MODE: fail_compilation
