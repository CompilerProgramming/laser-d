// TEST_MODE: compilable
// COMPILE_SEPARATELY:
// EXTRA_SOURCES: extra-files/module_basic.d extra-files/module_static.d extra-files/module_selective.d extra-files/module_public_source.d extra-files/module_reexport.d extra-files/module_implicit.d extra-files/module_cycle_a.d extra-files/module_cycle_b.d
// REQUIRED_ARGS: -Ilaser-d/extra-files

module modules_accepted;

import module_basic;
import module_basic;
import basicAlias = module_basic;
static import module_static;
import module_selective : renamedValue = selectedValue;
import module_reexport;
import module_implicit;
import module_cycle_a;
import module_cycle_b;

static assert(moduleName == "module_basic");
static assert(basicAlias.basicValue == 11);
static assert(module_static.staticValue == 13);
static assert(renamedValue == 17);
static assert(publicValue == 19);
static assert(implicitValue == 23);
static assert(cycleAValue == 29);
static assert(cycleBValue == 31);
