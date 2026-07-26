// TEST_MODE: compilable
// Upstream source: compiler/test/compilable/isreturnonstack.d

struct S
{
    int[10] a;
}

int test1();
S test2();

static assert(!__traits(isReturnOnStack, test1));
static assert(__traits(isReturnOnStack, test2));
