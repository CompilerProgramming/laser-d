// TEST_MODE: compilable
// COMPILE_SEPARATELY:
// EXTRA_SOURCES: extra-files/private_declarations/source.d
// REQUIRED_ARGS: -Ilaser-d/extra-files

module private_declarations_accepted;

import private_declarations.source;

static assert(publicValue == 23);
static assert(hiddenSize == int.sizeof);
static assert(read(make(29)) == 29);
static assert(defaultConstructionWorks() == 0);
