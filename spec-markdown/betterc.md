---
title: BetterC
status: restricted
source: ../spec/betterc.dd
---

# Better C

BetterC is a subset of D that doesn't depend on the D runtime library, only the C runtime library.

*Warning:* While the D runtime library and standard library are not linked in, it is still possible to import several packages (``core.*`` and ``std.*``) and use some templates, types and function declarations without bodies.
However, these libraries were not written for BetterC, so you will need to determine which symbols may be used.
Expect cryptic compiler or linker errors.

## <a id="linking"></a>Linking

It is straightforward to link C functions and libraries into D programs.
    But linking D functions and libraries into C programs is not straightforward.

D programs generally require:

1. The D runtime library to be linked in, because many features of the core language require runtime library support.
2. The `main()` function to be written in D, to ensure that the required runtime library support is properly initialized.

To link D functions and libraries into C programs, it's necessary to only
    require the C runtime library to be linked in. This is accomplished by defining
    a subset of D that fits this requirement, called **BetterC**.

## <a id="better-c"></a>Better C

> **Implementation-defined:**
>
> **BetterC** is typically enabled by setting the `-betterC`
>     command line flag for the implementation.

In Laser-D, **BetterC** is always enabled. The command-line flag
    `-betterC` remains accepted for compatibility with D build tools, but
    is redundant. Configuration files and command-line options cannot disable
    or weaken BetterC mode.

When **BetterC** is enabled, the predefined
    [version](version.md) `D_BetterC`
    can be used for conditional compilation.

Consequently, Laser-D always defines `D_BetterC`.

An entire program can be written in **BetterC** by supplying a C `main()` function:

```d
extern(C) void main()
    {
        import core.stdc.stdio : printf;
        printf("Hello betterC\n");
    }
```

```console
> dmd -betterC hello.d && ./hello
Hello betterC
```

Limiting a program to this subset of runtime features is useful
    when targeting constrained environments where the use of such features
    is not practical or possible.

**BetterC** makes embedding D libraries in existing larger projects easier by:

1. Simplifying the process of integration at the build-system level
2. Removing the need to ensure that Druntime is properly initialized on calls to the library, for situations when an initialization step is not performed or would be difficult to insert before the library is used.
3. Mixing memory management strategies (GC + manual memory management) can be tricky, hence removing D's GC from the equation may be worthwhile sometimes.

> **Note:**
>
> BetterC and [ImportC](importc.md) are very different.
>     ImportC is an actual C compiler. BetterC is a subset of D that relies only on the
>     existence of the C Standard library.

## <a id="retained"></a>Retained Features

Nearly the full language remains available. Highlights include:

1. Unrestricted use of compile-time features
2. Full metaprogramming facilities
3. Nested functions, nested structs, delegates and [lambdas](expression.md#function_literals)
4. Member functions, constructors, destructors, operating overloading, etc.
5. The full module system
6. Array slicing, and array bounds checking
7. RAII (yes, it can work without exceptions)
8. `scope(exit)`
9. Memory safety protections
10. [Interfacing to C++](cpp_interface.md)
11. COM classes and C++ classes
12. `assert` failures are directed to the C runtime library
13. `switch` with strings
14. `final switch`
15. `unittest`
16. [`printf` format validation](../spec/interfaceToC.dd)

### <a id="unittests"></a>Running unittests in `-betterC`

While testing can be done without the `-betterC` flag, it is sometimes desirable to run the testsuite in `-betterC` too.
`unittest` blocks can be listed with the [`getUnitTests`](traits.md#getUnitTests) trait:

```d
unittest
{
   assert(0);
}

extern(C) void main()
{
    static foreach(u; __traits(getUnitTests, __traits(parent, main)))
        u();
}
```

```console
> dmd -betterC -unittest -run test.d
dmd_runpezoXK: foo.d:3: Assertion 0' failed.
```

However, in `-betterC`, `assert` expressions don't use Druntime's assert and are directed to `assert` from the C runtime library instead.

## <a id="consequences"></a>Unavailable Features

> **Laser-D:**
>
> `TypeInfo` and `ModuleInfo` are unconditionally unavailable.
>     Laser-D additionally rejects `typeid` during CTFE rather than retaining
>     upstream BetterC's compile-time-only `TypeInfo` behavior.

D features not available with **BetterC**:

1. Garbage Collection
2. TypeInfo and [`ModuleInfo`](../spec/abi.dd)
3. Classes
4. Built-in threading (e.g. core.thread)
5. Dynamic arrays (though slices of static arrays and pointers work)
6. Associative arrays
7. Exceptions
8. `synchronized` and core.sync
9. Static module constructors or destructors
