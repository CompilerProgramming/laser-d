// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/interpolated_expressions_rejected.d(14): Error: interpolated expression sequences are not supported in Laser-D; use ordinary strings and explicit formatting or arguments
laser-d/interpolated_expressions_rejected.d(15): Error: interpolated expression sequences are not supported in Laser-D; use ordinary strings and explicit formatting or arguments
laser-d/interpolated_expressions_rejected.d(16): Error: interpolated expression sequences are not supported in Laser-D; use ordinary strings and explicit formatting or arguments
---
*/

void interpolate(int value)
{
    auto quoted = i"value: $(value)";
    auto wysiwyg = i`value: $(value)`;
    auto tokens = iq{value: $(value)};
}
