// TEST_MODE: runnable

extern(C) int main(int argc, char** argv)
{
    if (argc < 1)
        return 1;
    return argv && argv[0] ? 0 : 2;
}
