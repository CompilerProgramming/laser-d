import core.stdc.stdint;
import core.stdc.stdarg : va_list;
import core.stdc.stdio : printf;
import core.stdc.stdlib : EXIT_FAILURE, EXIT_SUCCESS, free, malloc;
import core.stdc.string : memcpy, strlen;

extern(C) int main()
{
    static assert(int8_t.sizeof == 1);
    static assert(uint64_t.sizeof == 8);
    static assert(intptr_t.sizeof == (void*).sizeof);
    static assert(va_list.sizeof == (void*).sizeof);

    enum message = "Laser-D core.stdc";
    static assert(message.length == 17);

    char* copy = cast(char*) malloc(message.length + 1);
    if (copy is null)
        return EXIT_FAILURE;

    memcpy(copy, message.ptr, message.length + 1);
    if (strlen(copy) != message.length)
    {
        free(copy);
        return EXIT_FAILURE;
    }

    int result = printf("%s: %llu-bit C runtime link\n",
                        copy, cast(ulong) (uintptr_t.sizeof * 8));
    free(copy);
    return result < 0 ? EXIT_FAILURE : EXIT_SUCCESS;
}
