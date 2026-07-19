// TEST_MODE: compilable

// This is a parser-boundary regression test, not a decision that the complete
// C++ class or interface feature is supported by Laser-D.
extern(C++)
{
    class CppClass { }
    interface CppInterface { void method(); }
}
