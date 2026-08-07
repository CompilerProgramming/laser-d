// TEST_MODE: fail_compilation
// REQUIRED_ARGS: -Ilaser-d/extra-files

/*
TEST_OUTPUT:
---
laser-d/package_visibility_sibling_rejected.d(15): Error: undefined identifier `innerValue`
---
*/

module package_visibility.sibling;

import package_visibility.inner.source;

enum inaccessible = innerValue;
