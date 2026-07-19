// TEST_MODE: compilable

immutable(char)[] utf8 = "Laser-D";
immutable(wchar)[] utf16 = "Laser-D"w;
immutable(dchar)[] utf32 = "Laser-D"d;

immutable(char)[] trim(immutable(char)[] value)
{
    return value[1 .. $ - 1];
}

char[] view(ref char[4] storage)
{
    return storage[];
}

void fill(char[] destination, char value)
{
    destination[] = value;
}

void inspect(immutable(char)[] value)
{
    auto length = value.length;
    auto pointer = value.ptr;
    auto first = value[0];
    auto tail = value[1 .. $];
}

static assert("Laser-D".length == 7);
static assert("Laser-D"w.length == 7);
static assert("Laser-D"d.length == 7);
static assert(trim("abc") == "b");
