// TEST_MODE: compilable
// COMPILE_SEPARATELY:
// EXTRA_SOURCES: extra-files/package_feature/package.d extra-files/package_feature/api.d extra-files/package_feature/tools/package.d extra-files/package_feature/tools/format.d
// REQUIRED_ARGS: -Ilaser-d/extra-files

module package_modules_accepted;

import package_feature;
import package_feature.tools;

static assert(apiValue == 11);
static assert(formatValue == 13);
