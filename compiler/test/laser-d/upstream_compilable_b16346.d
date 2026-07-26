// TEST_MODE: compilable
// Upstream source: compiler/test/compilable/b16346.d

enum A { B }
static assert(is(typeof(A.B) == A));
static assert(is(typeof(A(A.B)) == A));
