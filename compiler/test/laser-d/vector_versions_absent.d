// TEST_MODE: compilable

version (D_SIMD)
    static assert(false, "D_SIMD must not be defined in Laser-D");
version (D_AVX)
    static assert(false, "D_AVX must not be defined in Laser-D");
version (D_AVX2)
    static assert(false, "D_AVX2 must not be defined in Laser-D");
