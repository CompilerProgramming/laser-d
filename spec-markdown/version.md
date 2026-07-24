---
title: Conditional compilation
status: restricted
source: ../spec/version.dd
---

# Conditional Compilation

*Conditional compilation* is the process of selecting which
        code to compile and which code to not compile.

```text
ConditionalDeclaration:
    Condition DeclarationBlock
    Condition DeclarationBlock else DeclarationBlock
    Condition : DeclDefs[]
    Condition DeclarationBlock else : DeclDefs[]

ConditionalStatement:
    Condition NoScopeNonEmptyStatement
    Condition NoScopeNonEmptyStatement else NoScopeNonEmptyStatement
```

If the Condition is satisfied, then the following
        *DeclarationBlock* or *Statement* is compiled in.
        If it is not satisfied, the *DeclarationBlock* or *Statement*
        after the optional `else` is compiled in.

Any *DeclarationBlock* or *Statement* that is not
        compiled in still must be syntactically correct.

No new scope is introduced, even if the
        *DeclarationBlock* or *Statement*
        is enclosed by `{ }`.

*ConditionalDeclaration*s and *ConditionalStatement*s
        can be nested.

The StaticAssert can be used
        to issue errors at compilation time for branches of the conditional
        compilation that are errors.

*Condition* comes in the following forms:

```text
Condition:
    VersionCondition
    DebugCondition
    StaticIfCondition
```

## <a id="version"></a>Version Condition

```text
VersionCondition:
    version ( Identifier )
    version ( unittest )
    version ( assert )
```

Versions enable multiple versions of a module to be implemented
        with a single source file.

The *VersionCondition* is satisfied if *Identifier*
        matches a *version identifier*.

The *version identifier* can be set on the command line
        by the [`-version` switch](https://dlang.org/dmd.html#switch-version)
        or in the module itself with a
        VersionSpecification, or they can be predefined
        by the compiler.

Version identifiers are in their own unique name space, they do
        not conflict with [debug identifiers](#version-specification)
        or other symbols in the module.
        Version identifiers defined in one module have no influence
        over other imported modules.

```d
int k;
version (Demo) // compile in this code block for the demo version
{
    int i;
    int k;    // error
k already defined

    i = 3;
}
x = i;      // uses the i declared above
```

```d
version (X86)
{
    ... // implement custom inline assembler version
}
else
{
    ... // use default
but slow
version
}
```

`version (unittest)` is satisfied if and only if the code is
        compiled with unit tests enabled (the [`-unittest`](https://dlang.org/dmd.html#switch-unittest) option on `dmd`).

## <a id="VersionSpecification"></a>Version Specification

```text
VersionSpecification:
    version = Identifier ;
```

A version specification defines a specific version identifier.
        This makes it straightforward to group
        a set of features under one major version, for example:

```d
version (ProfessionalEdition)
{
    version = FeatureA;
    version = FeatureB;
    version = FeatureC;
}
version (HomeEdition)
{
    version = FeatureA;
}
...
version (FeatureB)
{
    ... implement Feature B ...
}
```

Version identifiers may not be forward referenced:

```d
version (Foo)
{
    int x;
}
version = Foo;  // error
Foo already used
```

*VersionSpecification*s may only appear at module scope.

While the [debug](#debug) and version conditions
        superficially behave the same, they are intended for very different purposes. Debug statements
        are for adding debug code that is removed for the release version.
        Version statements are to aid in portability and multiple release
        versions.

Here's an example of a *full* version as opposed to
        a *demo* version:

```d
class Foo
{
    int a
b;

    version (full)
    {
        int extrafunctionality()
        {
            ...
            return 1;  // extra functionality is supported
        }
    }
    else // demo
    {
        int extrafunctionality()
        {
            return 0;  // extra functionality is not supported
        }
    }
}
```

Various different version builds can be built with a parameter
        to version:

```d
version (identifier) // add in version code if version
                         // keyword is identifier
{
    ... version code ...
}
```

This is presumably set by the command line as
        `-version=identifier`.

### <a id="PredefinedVersions"></a>Predefined Versions

Several environmental version identifiers and identifier
        name spaces are predefined for consistent usage.
        Version identifiers do not conflict
        with other identifiers in the code, they are in a separate name space.
        Predefined version identifiers are global, i.e. they apply to
        all modules being compiled and imported.

| Version Identifier | Description |
| --- | --- |
| *Host Compiler* |  |
| `DigitalMars` | DMD (Digital Mars D) |
| `GNU` | GDC (GNU D Compiler) |
| `LDC` | LDC (LLVM D Compiler) |
| `SDC` | SDC (Snazzy D Compiler) |
| *Target Operating System* |  |
| `Windows` | Microsoft Windows systems Win32 and Win64 |
| `Win32` | Microsoft 32-bit Windows systems |
| `Win64` | Microsoft 64-bit Windows systems |
| `linux` | All Linux systems |
| `Apple` | Apple systems OSX, iOS, TVOS, WatchOS and VisionOS |
| `OSX` | macOS |
| `iOS` | iOS |
| `TVOS` | tvOS |
| `WatchOS` | watchOS |
| `VisionOS` | visionOS |
| `FreeBSD` | FreeBSD |
| `OpenBSD` | OpenBSD |
| `NetBSD` | NetBSD |
| `DragonFlyBSD` | DragonFlyBSD |
| `BSD` | All other BSDs |
| `Solaris` | Solaris |
| `Posix` | All POSIX systems (includes Linux, FreeBSD, OS X, Solaris, etc.) |
| `AIX` | IBM Advanced Interactive eXecutive OS |
| `Haiku` | The Haiku operating system |
| `SkyOS` | The SkyOS operating system |
| `SysV3` | System V Release 3 |
| `SysV4` | System V Release 4 |
| `Hurd` | GNU Hurd |
| `Android` | The Android platform |
| `Emscripten` | The Emscripten platform |
| `PlayStation` | The PlayStation platform |
| `PlayStation4` | The PlayStation 4 platform |
| `FreeStanding` | An environment without an operating system (such as Bare-metal targets) |
| *Target Environment* |  |
| `Cygwin` | The Cygwin environment |
| `MinGW` | The MinGW environment |
| `CRuntime_Bionic` | Bionic C runtime |
| `CRuntime_DigitalMars` | DigitalMars C runtime |
| `CRuntime_Glibc` | Glibc C runtime |
| `CRuntime_Microsoft` | Microsoft C runtime |
| `CRuntime_Musl` | musl C runtime |
| `CRuntime_Newlib` | newlib C runtime |
| `CRuntime_UClibc` | uClibc C runtime |
| `CRuntime_WASI` | WASI C runtime |
| `CppRuntime_Clang` | Deprecated, use `CppRuntime_LLVM` instead |
| `CppRuntime_DigitalMars` | DigitalMars C++ runtime |
| `CppRuntime_Gcc` | Deprecated, use `CppRuntime_GNU` instead |
| `CppRuntime_LLVM` | LLVM libc++ C++ runtime |
| `CppRuntime_GNU` | GNU libstdc++ C++ runtime |
| `CppRuntime_Microsoft` | Microsoft C++ runtime |
| `CppRuntime_Sun` | Sun C++ runtime |
| *Target CPU and Instruction Set* |  |
| `X86` | Intel and AMD 32-bit processors |
| `X86_64` | Intel and AMD 64-bit processors |
| `ARM` | The ARM architecture (32-bit) (AArch32 et al) |
| `ARM_Thumb` | ARM in any Thumb mode |
| `ARM_SoftFloat` | The ARM `soft` floating point ABI |
| `ARM_SoftFP` | The ARM `softfp` floating point ABI |
| `ARM_HardFloat` | The ARM `hardfp` floating point ABI |
| `AArch64` | The Advanced RISC Machine architecture (64-bit) |
| `AsmJS` | The asm.js intermediate programming language |
| `AVR` | 8-bit Atmel AVR Microcontrollers |
| `Epiphany` | The Epiphany architecture |
| `PPC` | The PowerPC architecture, 32-bit |
| `PPC_SoftFloat` | The PowerPC soft float ABI |
| `PPC_HardFloat` | The PowerPC hard float ABI |
| `PPC64` | The PowerPC architecture, 64-bit |
| `IA64` | The Itanium architecture (64-bit) |
| `MIPS32` | The MIPS architecture, 32-bit |
| `MIPS64` | The MIPS architecture, 64-bit |
| `MIPS_O32` | The MIPS O32 ABI |
| `MIPS_N32` | The MIPS N32 ABI |
| `MIPS_O64` | The MIPS O64 ABI |
| `MIPS_N64` | The MIPS N64 ABI |
| `MIPS_EABI` | The MIPS EABI |
| `MIPS_SoftFloat` | The MIPS `soft-float` ABI |
| `MIPS_HardFloat` | The MIPS `hard-float` ABI |
| `MSP430` | The MSP430 architecture |
| `NVPTX` | The Nvidia Parallel Thread Execution (PTX) architecture, 32-bit |
| `NVPTX64` | The Nvidia Parallel Thread Execution (PTX) architecture, 64-bit |
| `RISCV32` | The RISC-V architecture, 32-bit |
| `RISCV64` | The RISC-V architecture, 64-bit |
| `SPARC` | The SPARC architecture, 32-bit |
| `SPARC_V8Plus` | The SPARC v8+ ABI |
| `SPARC_SoftFloat` | The SPARC soft float ABI |
| `SPARC_HardFloat` | The SPARC hard float ABI |
| `SPARC64` | The SPARC architecture, 64-bit |
| `S390` | The System/390 architecture, 32-bit |
| `SystemZ` | The System Z architecture, 64-bit |
| `HPPA` | The HP PA-RISC architecture, 32-bit |
| `HPPA64` | The HP PA-RISC architecture, 64-bit |
| `SH` | The SuperH architecture, 32-bit |
| `WebAssembly` | The WebAssembly virtual ISA (instruction set architecture), 32-bit |
| `WASI` | The WebAssembly System Interface |
| `Xtensa` | The Xtensa Architecture, 32-bit |
| `Alpha` | The Alpha architecture |
| `Alpha_SoftFloat` | The Alpha soft float ABI |
| `Alpha_HardFloat` | The Alpha hard float ABI |
| *Byte Order (endianess)* |  |
| `LittleEndian` | Byte order, least significant first |
| `BigEndian` | Byte order, most significant first |
| *Executable and Link Format* |  |
| `ELFv1` | Elf version 1 |
| `ELFv2` | Elf version 2 |
| *Miscellaneous* |  |
| `D_BetterC` | Always predefined. Laser-D's runtime-free compilation model cannot be disabled. |
| `D_Exceptions` | Exception handling is supported. Evaluates to `false` when compiling with command line switch [`-betterC`](https://dlang.org/dmd.html#switch-betterC) |
| `D_ModuleInfo` | [`ModuleInfo`](../spec/abi.dd) is supported. Evaluates to `false` when compiling with command line switch [`-betterC`](https://dlang.org/dmd.html#switch-betterC) |
| `D_TypeInfo` | Runtime type information (a.k.a `TypeInfo`) is supported. Evaluates to `false` when compiling with command line switch [`-betterC`](https://dlang.org/dmd.html#switch-betterC) |
| `D_Coverage` | [Code coverage analysis](https://dlang.org/articles/code_coverage.html) instrumentation (command line switch [`-cov`](https://dlang.org/dmd.html#switch-cov)) is being generated |
| `D_Ddoc` | [Ddoc](../spec/ddoc.dd) documentation (command line switch [`-D`](https://dlang.org/dmd.html#switch-D)) is being generated |
| `D_InlineAsm_X86` | Never predefined. |
| `D_InlineAsm_X86_64` | Never predefined. |
| `D_LP64` | **Pointers** are 64 bits (command line switch [`-m64`](https://dlang.org/dmd.html#switch-m64)). (Do not confuse this with C's LP64 model) |
| `D_X32` | Pointers are 32 bits, but words are still 64 bits (x32 ABI) (This can be defined in parallel to `X86_64`) |
| `D_HardFloat` | The target hardware has a floating-point unit |
| `D_SoftFloat` | The target hardware does not have a floating-point unit |
| `D_PIC` | Position Independent Code (command line switch [`-fPIC`](https://dlang.org/dmd-linux.html#switch-fPIC)) is being generated |
| `D_PIE` | Position Independent Executable (command line switch [`-fPIE`](https://dlang.org/dmd-linux.html#switch-fPIE)) is being generated |
| `D_SIMD` | Never predefined. |
| `D_AVX` | AVX Vector instructions are supported |
| `D_AVX2` | AVX2 Vector instructions are supported |
| `D_Version2` | This is a D version 2 compiler |
| `D_NoBoundsChecks` | Array bounds checks are disabled (command line switch [`-boundscheck=off`](https://dlang.org/dmd.html#switch-boundscheck)) |
| `D_ObjectiveC` | The target supports interfacing with Objective-C. > **Laser-D:** This identifier is never predefined because Objective-C interoperability is rejected. |
| `D_ProfileGC` | GC allocations being profiled (command line switch [`-profile=gc`](https://dlang.org/dmd.html#switch-profile)) |
| `D_Optimized` | Compiling with enabled optimizations (command line switch [`-O`](https://dlang.org/dmd.html#switch-O)) |
| `Core` | Defined when building the standard runtime |
| `Std` | Defined when building the standard library |
| `unittest` | Never predefined. |
| `assert` | Checks are being emitted for AssertExpressions |
| `D_PreConditions` | Checks are being emitted for [in contracts](function.md#contracts) |
| `D_PostConditions` | Checks are being emitted for [out contracts](function.md#contracts) |
| `D_Invariants` | Never predefined. |
| *Special Cases* |  |
| `none` | Never defined; used to just disable a section of code |
| `all` | Always defined; used as the opposite of `none` |

The following identifiers are defined, but are deprecated:

| Version Identifier | Description |
| --- | --- |
| `darwin` | The Darwin operating system; use `OSX` instead |
| `Thumb` | ARM in Thumb mode; use `ARM_Thumb` instead |
| `S390X` | The System/390X architecture, 64-bit; use `SystemZ` instead |

Others will be added as they make sense and new implementations appear.

To allow for future growth of the language, the version identifier namespace beginning with "D_"
        is reserved for identifiers indicating D language specification
        or new feature conformance. Further, all identifiers derived from
        the ones listed above by appending any character(s) are reserved. This
        means that e.g. `ARM_foo` and `Windows_bar` are reserved while
        `foo_ARM` and `bar_Windows` are not.

Predefined version identifiers from this list cannot
        be set from the command line or from version statements.
        (This prevents things like both `Windows` and `linux`
        being simultaneously set.)

Compiler vendor specific versions can be predefined if the
        trademarked vendor identifier prefixes it, as in:

```d
version (DigitalMars_funky_extension)
{
    ...
}
```

It is important to use the right version identifier for the right
        purpose. For example, use the vendor identifier when using a vendor
        specific feature. Use the operating system identifier when using
        an operating system specific feature, etc.

## <a id="debug"></a>Debug Condition

```text
DebugCondition:
    debug
    debug ( Identifier )
```

Two versions of programs are commonly built, a release build and a debug build.
        The debug build includes extra error checking code, test harnesses, pretty-printing code, etc.
        The debug statement conditionally compiles in its
        statement body.
        It is D's way of what in C is done
        with `#ifdef DEBUG` / `#endif` pairs.

The

```text
debug
```

 condition is satisfied when the
        [`-debug` switch](https://dlang.org/dmd.html#switch-debug) is
        passed to the compiler.

The

```text
debug ( *Identifier* )
```

 condition is satisfied
        when the debug identifier matches *Identifier*.

```d
class Foo
{
    int a
b;
debug:
    int flag;
}
```

### <a id="DebugStatement"></a>Debug Statement

A ConditionalStatement that has a DebugCondition is called
        a *DebugStatement*. *DebugStatements* have relaxed semantic checks in that
        `pure`, `@nogc`, `nothrow` and `@safe` checks are not done.
        Neither do *DebugStatements* influence the inference of `pure`, `@nogc`, `nothrow`
        and `@safe` attributes.

> **Undefined behavior:**
>
> Since these checks are bypassed, it is up to the programmer
>         to ensure the code is correct. For example, throwing an exception in a `nothrow`
>         function is undefined behavior.

> **Best practice:**
>
> This enables the easy insertion of code to provide debugging help, by bypassing the otherwise stringent attribute checks.
>         Never ship release code that has *DebugStatements* enabled.

## <a id="debug_specification"></a>Debug Specification

```text
DebugSpecification:
    debug = Identifier ;
```

Debug identifiers are set either by the command line switch
        `-debug=`*identifier* or by a *DebugSpecification*.

Debug specifications only affect the module they appear in, they
        do not affect any imported modules. Debug identifiers are in their
        own namespace, independent from version identifiers and other
        symbols.

It is illegal to forward reference a debug specification:

```d
debug (foo) writeln("Foo");
debug = foo;    // error
foo used before set
```

*DebugSpecification*s may only appear at module scope.

Various different debug builds can be built with a parameter to
        debug:

```d
debug (identifier) { } // add in debug code if debug keyword is identifier
```

These are presumably set on the command line, e.g.
        `-debug=`*identifier*.

## <a id="staticif"></a>Static If Condition

> **Laser-D:** `static if` is supported.

```text
StaticIfCondition:
    static if ( AssignExpression )
```

AssignExpression is implicitly converted to a boolean type, and is evaluated at compile time.
        The condition is satisfied if it evaluates to `true`.
        It is not satisfied if it evaluates to `false`.

It is an error if AssignExpression cannot be implicitly converted
        to a boolean type or if it cannot be evaluated at compile time.

*StaticIfCondition*s
        can appear in module, class, template, struct, union, or function scope.
        In function scope, the symbols referred to in the
        AssignExpression can be any that can normally be referenced
        by an expression at that point.

```d
const int i = 3;
int j = 4;

static if (i == 3)    // ok
at module scope
    int x;

class C
{
    const int k = 5;

    static if (i == 3) // ok
        int x;
    else
        long x;

    static if (j == 3) // error
j is not a constant
        int y;

    static if (k == 5) // ok
k is in current scope
        int z;
}
```

```d
d
template Int(int i)
{
    static if (i == 32)
        alias Int = int;
    else static if (i == 16)
        alias Int = short;
    else
        static assert(0); // not supported
}

Int!(32) a;  // a is an int
Int!(16) b;  // b is a short
Int!(17) c;  // error
static assert trips

```

A *StaticIfCondition* differs from an
        *IfStatement* in the following ways:

1. It can be used to conditionally compile declarations, not just statements.
2. It does not introduce a new scope even if `{ }` are used for conditionally compiled statements.
3. For unsatisfied conditions, the conditionally compiled code need only be syntactically correct. It does not have to be semantically correct.
4. It must be evaluatable at compile time.

## <a id="staticforeach"></a>Static Foreach

> **Laser-D:** `static foreach` is supported.

```text
StaticForeachDeclaration:
    StaticForeach DeclarationBlock
    StaticForeach : DeclDefs[]

StaticForeachStatement:
    StaticForeach NoScopeNonEmptyStatement

StaticForeach:
    static AggregateForeach
    static RangeForeach
```

`static foreach` expands its *DeclarationBlock* or *DeclDefs* into a
        series of declarations, each of which may reference any
        ForeachType symbols declared.

      - The aggregate/range bounds are evaluated at compile time and
        turned into a sequence of compile-time entities by evaluating
        corresponding code with a ForeachStatement/ForeachRangeStatement
        at compile time.
      - The body of the `static foreach` is then copied a
        number of times that corresponds to the number of elements of the
        sequence.
      - Within the i-th copy, the name of the `static foreach` element
        'variable' is bound to the i-th entry of the sequence, either as an `enum`
        variable declaration (for constants) or an `alias`
        declaration (for symbols). (In particular, `static foreach`
        variables are never runtime variables.)

```d
d
static foreach (i; [0, 1, 2, 3])
{
    pragma(msg, i);
}

```

`static foreach` supports multiple ForeachType
        variables in cases where the
        corresponding `foreach` statement supports them. (In this case,
        `static foreach` generates a compile-time sequence of tuples, and the
        tuples are subsequently unpacked during iteration).

```d
d
static foreach (i, v; ['a', 'b', 'c', 'd'])
{
    static assert(i + 'a' == v);
}

```

Like bodies of ConditionalDeclarations, a `static foreach`
        body does not introduce a new scope. Therefore, it can be
        used to add declarations to an existing scope:

```d
d
import std.range : iota;

static foreach (i; iota(0, 3))
{
    mixin(enum x, i,  = i;);
}

pragma(msg, x0, " ", x1," ", x2); // 0 1 2

```

Inside a function, if a new scope is desired for each expansion, use another set of braces:

```d
d
void fun()
{
    static foreach (s; ["hi", "hey", "hello"])
    {{
        enum len = s.length;    // local to each iteration
        static assert(len <= 5);
    }}

    static assert(!is(typeof(len)));
}

```

`static foreach` supports sequence expansion
        [like `foreach`](statement.md#foreach_over_tuples).

### <a id="break-continue"></a>`break` and `continue`

As `static foreach` is a code generation construct and not a
        loop, `break` and `continue` cannot be used to change control
        flow within it. Instead of breaking or continuing a suitable enclosing
        statement, such an usage yields an error (this is to prevent
        misunderstandings).

```d
int test(int x)
{
    int r = -1;
    switch(x)
    {
        static foreach (i; 0 .. 5)
        {
            case i:
                r = i;
                break; // error
        }
        default: break;
    }
    return r;
}

static foreach (i; 0 .. 10)
{
    static assert(test(i) == (i < 5 ? i : -1));
}
```

An explicit `break`/`continue` label can be used to
        avoid this limitation. (Note that `static foreach` itself
        cannot be broken nor continued even if it is explicitly
        labeled.)

```d
d
int test(int x)
{
    int r = -1;
    Lswitch: switch(x)
    {
        static foreach (i; 0 .. 5)
        {
            case i:
                r = i;
                break Lswitch;
        }
        default: break;
    }
    return r;
}

static foreach (i; 0 .. 10)
{
    static assert(test(i) == (i < 5 ? i : -1));
}

```

## <a id="StaticAssert"></a>Static Assert

> **Laser-D:** `static assert` is supported.

```text
StaticAssert:
    static assert ( ArgumentList ) ;
```

The first AssignExpression is evaluated at compile time, and converted
        to a boolean value. If the value is true, the static assert
        is ignored. If the value is false, an error diagnostic is issued
        and the compile fails.

On failure, any subsequent *AssignExpression*s will each be
        converted to string and then concatenated. The resulting string will
        be printed out along with the error diagnostic.

Unlike AssertExpressions, *StaticAssert*s are always
        checked and evaluated by the compiler unless they appear in an
        unsatisfied conditional.

```d
void foo()
{
    if (0)
    {
        assert(0);  // never trips
        static assert(0); // always trips
    }
    version (BAR)
    {
    }
    else
    {
        static assert(0); // trips when version BAR is not defined
    }
}
```

*StaticAssert* is useful tool for drawing attention to conditional
        configurations not supported in the code.
