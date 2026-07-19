// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/objective_c_linkage_rejected.d(12): Error: Objective-C linkage is not supported in Laser-D
laser-d/objective_c_linkage_rejected.d(14): Error: Objective-C linkage is not supported in Laser-D
laser-d/objective_c_linkage_rejected.d(16): Error: Objective-C linkage is not supported in Laser-D
---
*/

extern(Objective-C) class ObjcClass { }

extern(Objective-C) interface ObjcProtocol { }

extern(Objective-C) void objcFunction();
