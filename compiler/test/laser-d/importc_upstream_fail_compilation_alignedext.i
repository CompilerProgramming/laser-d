/* TEST_OUTPUT:
---
laser-d/importc_upstream_fail_compilation_alignedext.i(10): Error: __decspec(align(123)) must be an integer positive power of 2 and be <= 8,192
laser-d/importc_upstream_fail_compilation_alignedext.i(11): Error: __decspec(align(16384)) must be an integer positive power of 2 and be <= 8,192


---
*/

typedef struct __declspec(align(123)) S { int a; } S;
struct __declspec(align(16384)) T { int a; };
// TEST_MODE: fail_compilation
