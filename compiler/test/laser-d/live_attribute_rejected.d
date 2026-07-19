// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/live_attribute_rejected.d(12): Error: attribute `@live` is not supported in Laser-D
laser-d/live_attribute_rejected.d(16): Error: attribute `@live` is not supported in Laser-D
laser-d/live_attribute_rejected.d(20): Error: attribute `@live` is not supported in Laser-D
---
*/

@live void prefixLive()
{
}

void postfixLive() @live
{
}

alias LiveFunction = void function() @live;
