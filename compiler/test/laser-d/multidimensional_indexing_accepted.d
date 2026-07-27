// TEST_MODE: runnable

struct Range
{
    ulong lower;
    ulong upper;
}

struct Matrix
{
    enum rows = 3;
    enum columns = 4;
    int[rows * columns] storage;

    ulong opDollar(ulong dimension)()
        if (dimension < 2)
    {
        static if (dimension == 0)
            return rows;
        else
            return columns;
    }

    Range opSlice(ulong dimension)(ulong lower, ulong upper)
        if (dimension < 2)
    {
        return Range(lower, upper);
    }

    int opIndex(ulong row, ulong column)
    {
        return storage[row * columns + column];
    }

    int opIndex(Range selectedRows, ulong column)
    {
        int result;
        foreach (row; selectedRows.lower .. selectedRows.upper)
            result += storage[row * columns + column];
        return result;
    }

    int opIndex(ulong row, Range selectedColumns)
    {
        int result;
        foreach (column; selectedColumns.lower .. selectedColumns.upper)
            result += storage[row * columns + column];
        return result;
    }

    int opIndex(Range selectedRows, Range selectedColumns)
    {
        int result;
        foreach (row; selectedRows.lower .. selectedRows.upper)
            foreach (column; selectedColumns.lower .. selectedColumns.upper)
                result += storage[row * columns + column];
        return result;
    }

    void opIndexAssign(int value, ulong row, ulong column)
    {
        storage[row * columns + column] = value;
    }

    void opIndexAssign(int value, Range selectedRows, ulong column)
    {
        foreach (row; selectedRows.lower .. selectedRows.upper)
            storage[row * columns + column] = value;
    }

    void opIndexAssign(int value, Range selectedRows, Range selectedColumns)
    {
        foreach (row; selectedRows.lower .. selectedRows.upper)
            foreach (column; selectedColumns.lower .. selectedColumns.upper)
                storage[row * columns + column] = value;
    }

    void opIndexOpAssign(string operator : "+")(
        int value, ulong row, Range selectedColumns)
    {
        foreach (column; selectedColumns.lower .. selectedColumns.upper)
            storage[row * columns + column] += value;
    }

    void opIndexUnary(string operator : "++")(
        ulong row, ulong column)
    {
        ++storage[row * columns + column];
    }

    int opIndexUnary(string operator : "-")(
        Range selectedRows, ulong column)
    {
        return -opIndex(selectedRows, column);
    }
}

Matrix produce(Matrix* source, int* calls)
{
    ++*calls;
    return *source;
}

Matrix* selectMatrix(Matrix* source, int* calls)
{
    ++*calls;
    return source;
}

extern(C) int main()
{
    Matrix matrix;
    foreach (row; 0 .. Matrix.rows)
        foreach (column; 0 .. Matrix.columns)
            matrix[row, column] = cast(int) (row * 10 + column);

    if (matrix[2, 3] != 23 || matrix[$ - 1, $ - 1] != 23)
        return 1;
    if (matrix[1 .. $, 2] != 34)
        return 2;
    if (matrix[1, 1 .. $] != 36)
        return 3;
    if (matrix[0 .. 2, 1 .. 3] != 26)
        return 4;

    matrix[0 .. 2, 3] = 40;
    if (matrix[0, 3] != 40 || matrix[1, 3] != 40)
        return 5;

    matrix[1 .. 3, 0 .. 2] = 7;
    if (matrix[1, 0] != 7 || matrix[1, 1] != 7 ||
        matrix[2, 0] != 7 || matrix[2, 1] != 7)
        return 6;

    matrix[2, 1 .. $] += 5;
    if (matrix[2, 1] != 12 || matrix[2, 2] != 27 || matrix[2, 3] != 28)
        return 7;

    ++matrix[0, 0];
    if (matrix[0, 0] != 1)
        return 8;
    if (-matrix[0 .. 2, 2] != -(2 + 12))
        return 9;

    int calls;
    int last = produce(&matrix, &calls)[$ - 1, $ - 1];
    if (calls != 1 || last != 28)
        return 10;

    calls = 0;
    (*selectMatrix(&matrix, &calls))[0, 0 .. $] += 1;
    if (calls != 1 || matrix[0, 0] != 2 || matrix[0, 1] != 2 ||
        matrix[0, 2] != 3 || matrix[0, 3] != 41)
        return 11;

    return 0;
}
