// TEST_MODE: fail_compilation
// TRANSFORM_OUTPUT: remove_lines(^import path)

/*
TEST_OUTPUT:
---
laser-d/module_missing_import_rejected.d(12): Error: unable to read module `laser_d_missing_module`
laser-d/module_missing_import_rejected.d(12):        Expected 'laser_d_missing_module.d' or 'laser_d_missing_module/package.d' in one of the following import paths:
---
*/

import laser_d_missing_module;
