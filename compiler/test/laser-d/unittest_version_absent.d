// TEST_MODE: compilable

version (unittest)
{
    static assert(0, "Laser-D must not define the unittest version");
}
else
{
    enum unittestVersionIsAbsent = true;
}

static assert(unittestVersionIsAbsent);
