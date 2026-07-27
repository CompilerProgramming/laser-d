// TEST_MODE: compilable
// EXTRA_SOURCES: extra-files/minimal/object.d

static assert(is(string == immutable(char)[]));
static assert(is(wstring == immutable(wchar)[]));
static assert(is(dstring == immutable(dchar)[]));

void useAliases()
{
    string narrow = "Laser-D";
    wstring wide = "Laser-D"w;
    dstring doubleWide = "Laser-D"d;
}
