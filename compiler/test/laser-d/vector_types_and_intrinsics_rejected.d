// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/vector_types_and_intrinsics_rejected.d(13): Error: vector types are not supported in Laser-D
laser-d/vector_types_and_intrinsics_rejected.d(17): Error: vector intrinsics are not supported in Laser-D
laser-d/vector_types_and_intrinsics_rejected.d(18): Error: vector intrinsics are not supported in Laser-D
laser-d/vector_types_and_intrinsics_rejected.d(19): Error: vector intrinsics are not supported in Laser-D
---
*/

alias IntVector = __vector(int[4]);

void rejectedIntrinsics()
{
    __simd(0, 0);
    __simd_sto(0, 0);
    __simd_ib(0, 0);
}
