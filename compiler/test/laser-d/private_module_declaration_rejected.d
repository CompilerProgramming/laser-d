// TEST_MODE: fail_compilation
// REQUIRED_ARGS: -Ilaser-d/extra-files

/*
TEST_OUTPUT:
---
laser-d/private_module_declaration_rejected.d(15): Error: undefined identifier `moduleValue`
---
*/

module private_module_declaration_rejected;

import private_declarations.source;

enum inaccessible = moduleValue;
