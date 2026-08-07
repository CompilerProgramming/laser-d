// TEST_MODE: fail_compilation
// REQUIRED_ARGS: -Ilaser-d/extra-files

/*
TEST_OUTPUT:
---
laser-d/private_member_rejected.d(19): Error: no property `value` for `value` of type `private_declarations.source.Vault`
$p:source.d$(21):        struct `Vault` defined here
laser-d/private_member_rejected.d(19): Error: function calls require explicit `()` in Laser-D
---
*/

module private_member_rejected;

import private_declarations.source;

int expose(Vault value)
{
    return value.value;
}
