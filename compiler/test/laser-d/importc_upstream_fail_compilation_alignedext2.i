/* TEST_OUTPUT:
---
laser-d/importc_upstream_fail_compilation_alignedext2.i(8): Error: alignment must be an integer positive power of 2, not 0x7b
laser-d/importc_upstream_fail_compilation_alignedext2.i(9): Error: alignment must be an integer positive power of 2, not 0x10000
---
*/

typedef struct __attribute__((aligned(123))) U { int a; } S;
struct __attribute__((aligned(65536))) V { int a; };
// TEST_MODE: fail_compilation
