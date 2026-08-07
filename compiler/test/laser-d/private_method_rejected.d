// TEST_MODE: fail_compilation
// REQUIRED_ARGS: -Ilaser-d/extra-files

/*
TEST_OUTPUT:
---
laser-d/private_method_rejected.d(18): Error: no property `valueInsideModule` for `value` of type `private_declarations.source.Vault`
$p:source.d$(21):        struct `Vault` defined here
---
*/

module private_method_rejected;

import private_declarations.source;

int expose(Vault value)
{
    return value.valueInsideModule();
}
