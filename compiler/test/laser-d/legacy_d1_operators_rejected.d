// TEST_MODE: fail_compilation

struct LegacyOperators
{
    int opAdd(int value) { return value; }
    int opAdd_r(int value) { return value; }
    int opAnd(int value) { return value; }
    int opShl_r(int value) { return value; }
    int opCat(int value) { return value; }
    int opNeg() { return 0; }
    int opPostInc() { return 0; }
    int opStar() { return 0; }
    int opIn_r(int value) { return value; }
    int opAddAssign(int value) { return value; }
    int opUShrAssign(int value) { return value; }
}

/*
TEST_OUTPUT:
---
laser-d/legacy_d1_operators_rejected.d(5): Error: legacy D1 operator hook `opAdd` is not supported in Laser-D; use modern operator templates
laser-d/legacy_d1_operators_rejected.d(6): Error: legacy D1 operator hook `opAdd_r` is not supported in Laser-D; use modern operator templates
laser-d/legacy_d1_operators_rejected.d(7): Error: legacy D1 operator hook `opAnd` is not supported in Laser-D; use modern operator templates
laser-d/legacy_d1_operators_rejected.d(8): Error: legacy D1 operator hook `opShl_r` is not supported in Laser-D; use modern operator templates
laser-d/legacy_d1_operators_rejected.d(9): Error: legacy D1 operator hook `opCat` is not supported in Laser-D; use modern operator templates
laser-d/legacy_d1_operators_rejected.d(10): Error: legacy D1 operator hook `opNeg` is not supported in Laser-D; use modern operator templates
laser-d/legacy_d1_operators_rejected.d(11): Error: legacy D1 operator hook `opPostInc` is not supported in Laser-D; use modern operator templates
laser-d/legacy_d1_operators_rejected.d(12): Error: legacy D1 operator hook `opStar` is not supported in Laser-D; use modern operator templates
laser-d/legacy_d1_operators_rejected.d(13): Error: legacy D1 operator hook `opIn_r` is not supported in Laser-D; use modern operator templates
laser-d/legacy_d1_operators_rejected.d(14): Error: legacy D1 operator hook `opAddAssign` is not supported in Laser-D; use modern operator templates
laser-d/legacy_d1_operators_rejected.d(15): Error: legacy D1 operator hook `opUShrAssign` is not supported in Laser-D; use modern operator templates
---
*/
