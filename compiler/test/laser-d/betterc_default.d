// Laser-D must define D_BetterC without requiring a command-line switch.
version (D_BetterC)
{
}
else
{
    static assert(0, "Laser-D must always compile in BetterC mode");
}

extern(C) int main()
{
    return 0;
}
