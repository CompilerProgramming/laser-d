/* REQUIRED_ARGS: -de
TEST_OUTPUT:
---
laser-d/importc_upstream_fail_compilation_cdeprecated.i(22): Deprecation: function `importc_upstream_fail_compilation_cdeprecated.mars` is deprecated
laser-d/importc_upstream_fail_compilation_cdeprecated.i(14):        `mars` is declared here
laser-d/importc_upstream_fail_compilation_cdeprecated.i(23): Deprecation: function `importc_upstream_fail_compilation_cdeprecated.jupiter` is deprecated - jumping jupiter
laser-d/importc_upstream_fail_compilation_cdeprecated.i(15):        `jupiter` is declared here
laser-d/importc_upstream_fail_compilation_cdeprecated.i(24): Deprecation: function `importc_upstream_fail_compilation_cdeprecated.saturn` is deprecated
laser-d/importc_upstream_fail_compilation_cdeprecated.i(16):        `saturn` is declared here
laser-d/importc_upstream_fail_compilation_cdeprecated.i(25): Deprecation: function `importc_upstream_fail_compilation_cdeprecated.neptune` is deprecated - spinning neptune
laser-d/importc_upstream_fail_compilation_cdeprecated.i(17):        `neptune` is declared here
---
*/
__declspec(deprecated) int mars();
__declspec(deprecated("jumping jupiter")) int jupiter();
__attribute__((deprecated)) extern int saturn();
__attribute__((deprecated("spinning neptune"))) extern int neptune();

int test()
{
    return
        mars() +
        jupiter() +
        saturn() +
        neptune();
}
// TEST_MODE: fail_compilation
