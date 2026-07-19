// TEST_MODE: runnable
// EXTRA_SOURCES: extra-files/importc_api.i

import importc_api;

static assert(CPoint.sizeof == 2 * int.sizeof);
static assert(CPoint.x.offsetof == 0);
static assert(CPoint.y.offsetof == int.sizeof);
static assert(blue == 4);

// C long double remains available through ImportC's internal representation,
// even though Laser-D source cannot spell the D `real` type.
static assert(typeof(importc_extended).sizeof >= double.sizeof);

extern(C) int main()
{
    CPoint point = make_point(20, 22);
    if (sum_point(point) != 42)
        return 1;
    if (importc_global != 7)
        return 2;
    return 0;
}
