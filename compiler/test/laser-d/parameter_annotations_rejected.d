// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/parameter_annotations_rejected.d(14): Error: `scope` parameters are not supported in Laser-D; use `in`, `out`, or `ref`
laser-d/parameter_annotations_rejected.d(15): Error: `lazy` parameters are not supported in Laser-D; use `in`, `out`, or `ref`
laser-d/parameter_annotations_rejected.d(16): Error: `return` parameter annotations are not supported in Laser-D; use `in`, `out`, or `ref`
laser-d/parameter_annotations_rejected.d(17): Error: `auto ref` parameters are not supported in Laser-D; use `ref`
laser-d/parameter_annotations_rejected.d(18): Error: `final` parameters are not supported in Laser-D; use `in`, `out`, or `ref`
---
*/

void scoped(scope int value);
void deferred(lazy int value);
int* borrowed(return ref int value);
void inferred(T)(auto ref T value);
void fixed(final int value);
