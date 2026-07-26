// TEST_MODE: compilable
// Upstream source: compiler/test/compilable/betterc.d
// The upstream test's explicit -betterC argument is unnecessary because
// Laser-D always uses BetterC mode.

version (D_BetterC)
{
}
else
{
    static assert(0);
}

version (D_ModuleInfo)
{
    static assert(0);
}

version (D_Exceptions)
{
    static assert(0);
}

version (D_TypeInfo)
{
    static assert(0);
}
