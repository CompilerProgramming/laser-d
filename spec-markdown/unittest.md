---
title: Unit tests
status: rejected
source: ../spec/unittest.dd
---

# Unit Tests

> **Laser-D:**
>
> Laser-D does not include D's built-in unit-test framework. Tests
> are ordinary Laser-D programs with explicit functions, explicit calls, and one
> of the supported C entry points.

## <a id="declarations"></a>Unit-Test Declarations

> **Rejected in Laser-D:**
>
> The `unittest` block declaration is rejected at module, aggregate, and template scope. It is rejected regardless of compiler options;
> the compiler never silently skips its contents.

A test should instead be written as an ordinary function and invoked
explicitly from:

```d
extern(C) int main()
{
    return runTests();
}
```

This keeps control flow visible and gives tests the same language and runtime
model as other Laser-D programs.

## <a id="enabling"></a>Compiler Option and Version

> **Rejected in Laser-D:**
>
> The `-unittest` compiler option is rejected. The predefined
> `unittest` version condition is never enabled by the Laser-D compiler.

## <a id="discovery"></a>Unit-Test Discovery

> **Rejected in Laser-D:**
>
> `__traits(getUnitTests, symbol)` is rejected. Laser-D does
> not generate hidden unit-test functions or provide a reflection protocol for
> discovering them.

## <a id="execution"></a>Execution Model

Laser-D performs no automatic test registration or execution before
`main`. Test ordering, result reporting, and failure propagation are
implemented explicitly by the test program or its C-compatible test harness.
This requires neither ModuleInfo nor druntime.

## <a id="assertions"></a>Assertions

Runtime `assert` expressions are rejected independently of the built-in
unit-test framework. Compiler-only `static assert` declarations remain
supported.
