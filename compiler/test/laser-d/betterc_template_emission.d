// TEST_MODE: runnable
// COMPILE_SEPARATELY:
// EXTRA_SOURCES: extra-files/template_emission.d
// REQUIRED_ARGS: -Ilaser-d/extra-files

import template_emission;

extern(C) int main()
{
    Value value;
    Wrapper.apply(value);
    return 0;
}
