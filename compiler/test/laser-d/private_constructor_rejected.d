// TEST_MODE: fail_compilation
// REQUIRED_ARGS: -Ilaser-d/extra-files

/*
TEST_OUTPUT:
---
laser-d/private_constructor_rejected.d(15): Error: constructor `private_declarations.source.Vault.this` of type `nothrow @nogc ref @system Vault(int value)` is not accessible from module `private_constructor_rejected`
---
*/

module private_constructor_rejected;

import private_declarations.source;

enum inaccessible = Vault(37);
