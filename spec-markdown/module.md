---
title: Modules
status: restricted
source: ../spec/module.dd
---

# Modules

> **Laser-D normative:**
>
> Core modules and imports are supported. This includes explicit and
> file-name-derived module names; ordinary, aliased, selective, renamed, static, private, and public imports; cyclic imports; and separate compilation.
> `ModuleInfo` runtime descriptors are not generated or exposed. Module lifecycle
> constructors and destructors are rejected. Package-specific facilities and
> edition-qualified modules are not yet classified; user-defined module
> attributes are rejected separately.

```text
Module:
    ModuleDeclaration
    ModuleDeclaration DeclDefs
    DeclDefs

DeclDefs:
    DeclDef
    DeclDef DeclDefs

DeclDef:
    AttributeSpecifier
    Declaration
    Constructor
    EmptyDeclaration

EmptyDeclaration:
    ;
```

Modules have a one-to-one correspondence with source files. When not
explicitly set via a ModuleDeclaration, a module's name defaults
to the name of the file stripped of its path and extension.

A module's name automatically acts as a namespace scope for its contents. Modules
superficially resemble classes, but differ in that:

- Only one instance of a module exists, and it is statically allocated.
- Modules do not have virtual tables.
- Modules do not inherit, do not have super modules, etc.
- A source file may contain only one module.
- Symbols in a module can be imported.
- Modules are always compiled at global scope and are unaffected by surrounding attributes or other modifiers.

Modules can be grouped into hierarchies called *packages*.

Modules offer several guarantees:

- The order in which modules are imported does not affect their semantics.
- The semantics of a module are not affected by the scope in which it is imported.
- If a module `C` imports modules `A` and `B`, any modifications to `B` will not silently change code in `C` that is dependent on `A`.

## <a id="module_declaration"></a>Module Declaration

> **Laser-D normative:**
>
> A module declaration consists of `module`, its qualified
> name, and a semicolon. If it is omitted, the module name is derived from the
> source file name. Attributes and edition qualifiers are not part of the
> normative module-declaration grammar.

The *ModuleDeclaration* sets the name of the module and what package it
belongs to. If absent, the module name is taken to be the same name (stripped of
path and extension) of the source file name.

```text
ModuleDeclaration:
    module ModuleFullyQualifiedName ;

ModuleFullyQualifiedName:
    ModuleName
    Packages . ModuleName

ModuleName:
    Identifier
```

> **Excluded from Laser-D:**
>
> User-defined attributes on module declarations are not
> supported. Module deprecation and edition-qualified declarations remain under
> review and are therefore not included in the normative grammar.

```text
Packages:
    PackageName
    Packages . PackageName

PackageName:
    Identifier
```

The *Identifier*s preceding the rightmost *Identifier* are the *Packages* that the
module is in. The packages correspond to directory names in the source file
path. Package and module names cannot be Keywords.

If present, the *ModuleDeclaration* must be the first and only such declaration
in the source file, and may be preceded only by comments and `#line` directives.

Example:

```d
module c.stdio; // module stdio in the c package
```

By convention, package and module names are all lower case. This is because
these names have a one-to-one correspondence with the operating system's
directory and file names, and many file systems are not case sensitive. Using all
lower case package and module names will avoid or minimize problems when moving projects
between dissimilar file systems.

If the file name of a module is an invalid module name (e.g.
`foo-bar.d`), use a module declaration to set a valid module name:

```d
module foo_bar;
```

> **Implementation-defined:** 1. The mapping of package and module identifiers to directory and file names.

> **Best practice:**
>
> 1. PackageNames and ModuleNames should be composed of the ASCII characters lower case letters, digits or `_` to ensure maximum portability and compatibility with various file systems.
> 2. The file names for packages and modules should be composed only of the ASCII lower case letters, digits, and `_`s, and should not be a Keyword.

### <a id="advanced_module_declarations"></a>Advanced Module Declarations

> **Under review:**
>
> Module deprecation, edition-qualified module
> declarations, package modules, and package visibility have not yet been
> classified. They are not portability guarantees in Laser-D.

## <a id="ImportDeclaration"></a>Import Declaration

> **Laser-D normative:**
>
> Import declarations are supported, including module aliases, selective and renamed bindings, static imports, visibility-controlled imports, public re-exports, duplicate imports, and cyclic module graphs. A private import
> does not re-export symbols.

Symbols from one module are made available in another module by using the
*ImportDeclaration*:

```text
ImportDeclaration:
    import ImportList ;
    static import ImportList ;

ImportList:
    Import
    ImportBindings
    Import , ImportList

Import:
    ModuleFullyQualifiedName
    ModuleAliasIdentifier = ModuleFullyQualifiedName

ImportBindings:
    Import : ImportBindList

ImportBindList:
    ImportBind
    ImportBind , ImportBindList

ImportBind:
    Identifier
    Identifier = Identifier

ModuleAliasIdentifier:
    Identifier
```

There are several forms of the *ImportDeclaration*, from generalized to
fine-grained importing.

The order in which *ImportDeclaration*s occur has no significance.

*ModuleFullyQualifiedName*s in the *ImportDeclaration* must be fully
qualified with whatever packages they are in. They are not considered to be
relative to the module that imports them.

> **Implementation-defined:** 1. How the compiler resolves the package and module identifiers in an import declaration to its corresponding source files.

### <a id="name_lookup"></a>Symbol Name Lookup

The simplest form of importing is to just list the modules being imported:

```d
module myapp.main;

import std.stdio; // import module stdio from package std

void run()
{
    import myapp.foo;  // visible in run and its nested scopes
    void nested()
    {
        import myapp.bar;  // import module myapp.bar in this function' scope
        writeln("hello!");  // calls std.stdio.writeln
    }
}
```

When a symbol name is used unqualified, a two-phase lookup is used.
First, the module scope is searched, starting from the innermost scope.
For example, in the previous example, while looking for `writeln`, the order will be:

- Declarations inside `nested`.
- Declarations inside `run`.
- Declarations at module scope.

If the first lookup isn't successful, a second one is performed on imports.
Imports in unrelated scopes are ignored, while imports introduced by a mixed-in
`template` participate according to the template-mixin rules.

Symbol lookup stops as soon as a matching symbol is found. If two symbols with the
same name are found at the same lookup phase, this ambiguity will result in a
compilation error.

```d
module A;
void foo();
void bar();
```

```d
module B;
void foo();
void bar();
```

```d
module C;
import A;
void foo();
void test()
{
    foo(); // C.foo() is called
it is found before imports are searched
    bar(); // A.bar() is called
since imports are searched
}
```

```d
module D;
import A;
import B;
void test()
{
    foo();   // error
A.foo() or B.foo() ?
    A.foo(); // ok
call A.foo()
    B.foo(); // ok
call B.foo()
}
```

```d
module E;
import A;
import B;
alias foo = B.foo;
void test()
{
    foo();   // call B.foo()
    A.foo(); // call A.foo()
    B.foo(); // call B.foo()
}
```

### <a id="public_imports"></a>Public Imports

By default, imports are *private*. This means that if module A imports
module B, and module B imports module C, then names inside C are visible only inside
B and not inside A.

An import can be explicitly declared *public*, which will cause
names from the imported module to be visible to further imports. So in the above
example where module A imports module B, if module B *publicly* imports
module C, names from C will be visible in A as well.

All symbols from a publicly imported module are also aliased in the
importing module. Thus in the above example if C contains the name foo, it will
be accessible in A as `foo`, `B.foo` and `C.foo`.

For another example:

```d
module W;
void foo() { }
```

```d
module X;
void bar() { }
```

```d
module Y;
import W;
public import X;
...
foo();  // calls W.foo()
bar();  // calls X.bar()
```

```d
module Z;
import Y;
...
foo();   // error
foo() is undefined
bar();   // ok
calls X.bar()
X.bar(); // ditto
Y.bar(); // ok
Y.bar() is an alias to X.bar()
```

### <a id="static_imports"></a>Static Imports

A static import requires the use of a fully qualified name
to reference the module's names:

```d
static import std.stdio;

void main()
{
    writeln("hello!");           // error
writeln is undefined
    std.stdio.writeln("hello!"); // ok
writeln is fully qualified
}
```

### <a id="renamed_imports"></a>Renamed Imports

A local name for an import can be given, through which all references to the
module's symbols must be qualified with:

```d
d
import io = std.stdio;

void main()
{
    io.writeln("hello!");        // ok
calls std.stdio.writeln
    std.stdio.writeln("hello!"); // error
std is undefined
    writeln("hello!");           // error
writeln is undefined
}

```

> **Best practice:** Renamed imports are handy when dealing with very long import names.

### <a id="selective_imports"></a>Selective Imports

Specific symbols can be exclusively imported from a module and bound into
the current namespace:

```d
d
import std.stdio : writeln
foo = write;

void main()
{
    std.stdio.writeln("hello!"); // error
std is undefined
    writeln("hello!");           // ok
writeln bound into current namespace
    write("world");              // error
write is undefined
    foo("world");                // ok
calls std.stdio.write()
    fwritefln(stdout, "abc");    // error
fwritefln undefined
}

```

`static` cannot be used with selective imports.

### <a id="renamed_selective_imports"></a>Renamed and Selective Imports

When renaming and selective importing are combined:

```d
d
import io = std.stdio : foo = writeln;

void main()
{
    writeln("bar");           // error
writeln is undefined
    std.stdio.foo("bar");     // error
foo is bound into current namespace
    std.stdio.writeln("bar"); // error
std is undefined
    foo("bar");               // ok
foo is bound into current namespace
// FQN not required
    io.writeln("bar");        // ok
io=std.stdio bound the name io in
                              // the current namespace to refer to the entire
                              //   module
    io.foo("bar");            // error
foo is bound into current namespace
// foo is not a member of io
}

```

### <a id="scoped_imports"></a>Scoped Imports

Import declarations may be used at any scope. For example:

```d
d
void main()
{
    import std.stdio;
    writeln("bar");
}

```

The imports are looked up to satisfy any unresolved symbols at that scope.
Imported symbols may hide symbols from outer scopes.

In function scopes, imported symbols only become visible after the import
declaration lexically appears in the function body. In other words, imported
symbols at function scope cannot be forward referenced.

```d
d
void main()
{
    void writeln(string) {}
    void foo()
    {
        writeln("bar"); // calls main.writeln
        import std.stdio;
        writeln("bar"); // calls std.stdio.writeln
        void writeln(string) {}
        writeln("bar"); // calls main.foo.writeln
    }
    writeln("bar"); // calls main.writeln
    std.stdio.writeln("bar");  // error
std is undefined
}

```

## <a id="module_scope_operators"></a>Module Scope Operator

A leading dot (`.`) causes the
    identifier to be looked up in the module scope.

```d
d
enum x = 1;

extern(C) int main()
{
    int x = 5;
    return x == 5 && .x == 1 ? 0 : 1;
}

```

## <a id="staticorder"></a>No Module Lifecycle

> **Excluded from Laser-D:**
>
> Laser-D has no module or thread lifecycle execution. It rejects
> `static this()`, `static ~this()`, their `shared` forms, and the same
> declarations nested in aggregates or templates. Import order therefore never
> establishes a runtime construction or destruction order. Ordinary instance
> struct constructors are unaffected.

Mutable module storage, `shared`, and `__gshared` are also rejected.
Manifest constants and deeply immutable static data require no lifecycle hook.
ImportC globals remain available under the ImportC rules.

## <a id="order_of_unittests"></a>Order of Unit tests

> **Under review:**
>
> Language-level unit-test declarations have not yet been
> classified. Laser-D therefore does not currently specify module-level unit-test
> discovery or execution order.

## <a id="MixinDeclaration"></a>String Mixin Declarations (Excluded)

> **Excluded from Laser-D:**
>
> String mixin declarations are not part of Laser-D and the
> *MixinDeclaration* production is omitted from DeclDef. Template
> mixin declarations and instantiations are separate constructs described in the
> template-mixin chapter.

## <a id="PackageModule"></a>Package Modules (Under Review)

> **Under review:**
>
> Package modules and package-specific visibility have not
> yet been classified. The following material describes the upstream D facility
> for review and is not currently normative Laser-D text.

A package module can be used to publicly import other modules, while
providing a simpler import syntax. This enables the conversion of a module into a package
of modules, without breaking existing code which uses that module. Example of a
set of library modules:

**libweb/client.d:**

```d
module libweb.client;

void runClient() { }
```

**libweb/server.d:**

```d
module libweb.server;

void runServer() { }
```

**libweb/package.d:**

```d
module libweb;

public import libweb.client;
public import libweb.server;
```

The package module's file name must be `package.d`. The module name
is declared to be the fully qualified name of the package. Package modules can
be imported just like any other modules:

**test.d:**

```d
module test;

// import the package module
import libweb;

void main()
{
    runClient();
    runServer();
}
```

A package module can be nested inside of a sub-package:

**libweb/utils/package.d:**

```d
// must be declared as the fully qualified name of the package
not just 'utils'
module libweb.utils;

// publicly import modules from within the 'libweb.utils' package.
public import libweb.utils.conv;
public import libweb.utils.text;
```

The package module can then be imported with the standard module import
declaration:

**test.d:**

```d
module test;

// import the package module
import libweb.utils;

void main() { }
```
