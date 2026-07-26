// TEST_MODE: compilable
// Upstream source: compiler/test/compilable/b19829.d

static assert(!__traits(isSame, (i){ return i,x.value; }, a => a.value));
static assert(!__traits(isSame, i => x[i].value, a => a.value));
static assert(!__traits(isSame, i => [i].value, a => a.value));
static assert(__traits(isSame, i => i.value, a => a.value));
