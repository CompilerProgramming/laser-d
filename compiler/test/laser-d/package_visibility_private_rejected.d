// TEST_MODE: fail_compilation
// REQUIRED_ARGS: -Ilaser-d/extra-files

/*
TEST_OUTPUT:
---
laser-d/package_visibility_private_rejected.d(15): Error: undefined identifier `privateValue`
---
*/

module package_visibility.inner.private_peer;

import package_visibility.inner.source;

enum inaccessible = privateValue;
