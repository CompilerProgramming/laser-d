/* TEST_OUTPUT:
---
laser-d/importc_upstream_fail_compilation_attrpure.i(11): Error: `pure` function `importc_upstream_fail_compilation_attrpure.pureAsSnow` cannot call impure function `importc_upstream_fail_compilation_attrpure.impure`
---
*/

void impure();

__attribute__((pure)) void pureAsSnow()
{
    impure();
}
// TEST_MODE: fail_compilation
