// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/string_mutation_rejected.d(14): Error: cannot modify `immutable` expression `text[0]`
laser-d/string_mutation_rejected.d(19): Error: cannot implicitly convert expression `"Laser-D"` of type `string` to `char[]`
---
*/

void mutateLiteral()
{
    string text = "Laser-D";
    text[0] = 'l';
}

void convertLiteralToMutable()
{
    char[] text = "Laser-D";
}
