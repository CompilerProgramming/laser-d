// TEST_MODE: fail_compilation
// REQUIRED_ARGS: -Ilaser-d/extra-files

/*
TEST_OUTPUT:
---
laser-d/package_visibility_rejected.d(15): Error: undefined identifier `treeValue`
---
*/

module unrelated.visibility;

import package_visibility.inner.source;

enum inaccessible = treeValue;
