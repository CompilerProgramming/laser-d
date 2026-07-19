// TEST_MODE: fail_compilation
// EXTRA_SOURCES: extra-files/module_private_source.d extra-files/module_private_importer.d
// REQUIRED_ARGS: -Ilaser-d/extra-files

/*
TEST_OUTPUT:
---
laser-d/module_private_import_rejected.d(15): Error: undefined identifier `privateValue`
---
*/

module module_private_import_rejected;

import module_private_importer;
enum exposed = privateValue;
