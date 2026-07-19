// TEST_MODE: compilable

module runtime_metadata_absent;

static assert(!is(TypeInfo));
static assert(!is(ModuleInfo));
static assert(!__traits(compiles, typeid(int)));
