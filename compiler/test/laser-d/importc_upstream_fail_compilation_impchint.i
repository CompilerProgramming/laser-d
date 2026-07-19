/*
TEST_OUTPUT:
---
laser-d/importc_upstream_fail_compilation_impchint.i(33): Error: `bool` is not defined, perhaps `#include <stdbool.h>` ?
laser-d/importc_upstream_fail_compilation_impchint.i(33): Error: `true` is not defined, perhaps `#include <stdbool.h>` is needed?
laser-d/importc_upstream_fail_compilation_impchint.i(34): Error: `nullptr_t` is not defined, perhaps `#include <stddef.h>` ?
laser-d/importc_upstream_fail_compilation_impchint.i(35): Error: `int8_t` is not defined, perhaps `#include <stdint.h>` ?
laser-d/importc_upstream_fail_compilation_impchint.i(35): Error: `INT8_MAX` is not defined, perhaps `#include <stdint.h>` is needed?
laser-d/importc_upstream_fail_compilation_impchint.i(36): Error: `uint32_t` is not defined, perhaps `#include <stdint.h>` ?
laser-d/importc_upstream_fail_compilation_impchint.i(36): Error: `UINT32_MAX` is not defined, perhaps `#include <stdint.h>` is needed?
laser-d/importc_upstream_fail_compilation_impchint.i(37): Error: `wchar_t` is not defined, perhaps `#include <stddef.h>` ?
laser-d/importc_upstream_fail_compilation_impchint.i(37): Error: `WCHAR_MIN` is not defined, perhaps `#include <wchar.h>` is needed?
laser-d/importc_upstream_fail_compilation_impchint.i(38): Error: `FILE` is not defined, perhaps `#include <stdio.h>` is needed?
laser-d/importc_upstream_fail_compilation_impchint.i(38): Error: undefined identifier `f`
laser-d/importc_upstream_fail_compilation_impchint.i(39): Error: `fpos_t` is not defined, perhaps `#include <stdio.h>` ?
laser-d/importc_upstream_fail_compilation_impchint.i(39): Error: `EOF` is not defined, perhaps `#include <stdio.h>` is needed?
laser-d/importc_upstream_fail_compilation_impchint.i(40): Error: `EXIT_SUCCESS` is not defined, perhaps `#include <stdlib.h>` is needed?
laser-d/importc_upstream_fail_compilation_impchint.i(41): Error: `va_list` is not defined, perhaps `#include <stdarg.h>` ?
laser-d/importc_upstream_fail_compilation_impchint.i(43): Error: `exit` is not defined, perhaps `#include <stdlib.h>` is needed?
laser-d/importc_upstream_fail_compilation_impchint.i(44): Error: `getchar` is not defined, perhaps `#include <stdio.h>` is needed?
laser-d/importc_upstream_fail_compilation_impchint.i(45): Error: `offsetof` is not defined, perhaps `#include <stddef.h>` is needed?
laser-d/importc_upstream_fail_compilation_impchint.i(46): Error: `strcat` is not defined, perhaps `#include <string.h>` is needed?
laser-d/importc_upstream_fail_compilation_impchint.i(48): Error: `false` is not defined, perhaps `#include <stdbool.h>` is needed?
---
*/





int test(void)
{
    bool a = true;
    nullptr_t b;
    int8_t c = INT8_MAX;
    uint32_t d = UINT32_MAX;
    wchar_t e = WCHAR_MIN;
    FILE *f = NULL;
    fpos_t g = EOF;
    int h = EXIT_SUCCESS;
    va_list i;

    exit();
    getchar();
    offsetof();
    strcat();

    return false;
}
// TEST_MODE: fail_compilation
