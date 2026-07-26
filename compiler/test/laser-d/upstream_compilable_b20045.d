// TEST_MODE: compilable
// Upstream source: compiler/test/compilable/b20045.d

alias U = const ubyte[uint.sizeof]*;
static assert(is(U == const(ubyte[4]*)));
