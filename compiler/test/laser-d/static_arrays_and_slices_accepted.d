// TEST_MODE: runnable

extern(C) int main()
{
    enum literalCount = 3;
    int[literalCount] literalStorage = [10, 20, 30];
    int[3] globalStorage;
    globalStorage[0] = 10;
    globalStorage[1] = 20;
    globalStorage[2] = 30;
    int[4] storage;
    storage[0] = 1;
    storage[1] = 2;
    storage[2] = 3;
    storage[3] = 4;
    int[] whole = storage[];
    int[] middle = storage[1 .. 3];
    int[] pointerSlice = storage.ptr[0 .. storage.length];

    if (storage.length != 4 || whole.length != 4 || middle.length != 2)
        return 1;
    if (whole.ptr !is storage.ptr || pointerSlice.ptr !is storage.ptr)
        return 2;
    if (storage[0] != 1 || storage[$ - 1] != 4)
        return 3;
    if (middle[0] != 2 || middle[1] != 3)
        return 4;

    middle[0] = 22;
    if (storage[1] != 22)
        return 5;

    immutable(char)[] text = "Laser-D";
    if (text.length != 7 || text.ptr is null || text[0] != 'L' || text[$ - 1] != 'D')
        return 6;

    if (globalStorage[0] != 10 || globalStorage[2] != 30)
        return 7;
    if (literalStorage[0] != 10 || literalStorage[1] != 20 ||
        literalStorage[2] != 30)
        return 8;

    return 0;
}
