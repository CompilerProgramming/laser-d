// TEST_MODE: compilable
// Upstream source: compiler/test/compilable/fix21684.d
// https://issues.dlang.org/show_bug.cgi?id=21684

struct S
{
    int[100_000] a;
}
