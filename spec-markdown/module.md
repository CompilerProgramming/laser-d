---
title: Modules
status: restricted
source: ../spec/module.dd
---

# Modules

A Laser-D source file is a module. A module supplies a namespace, controls
which declarations are visible to another module, and is the unit of separate
compilation.

A module is not a runtime object. Importing a module does not construct an
instance or execute initialization code.

## Module declaration

```text
ModuleDeclaration:
    module ModuleFullyQualifiedName ;

ModuleFullyQualifiedName:
    ModuleName
    Packages . ModuleName

Packages:
    PackageName
    Packages . PackageName

ModuleName:
    Identifier

PackageName:
    Identifier
```

A module declaration sets the fully qualified name of the module:

```d
module geometry.matrix;
```

The declaration, when present, must be the first declaration in the source
file. It may be preceded only by comments and `#line` directives. A source file
may contain at most one module declaration.

When the declaration is omitted, the module name is the source filename with
its directory and extension removed. A file whose name is not a valid
identifier uses an explicit declaration:

```d
module geometry_matrix;
```

The identifiers before the final identifier form the package path. The mapping
from a qualified module name to directories and source files is
implementation-defined. Lowercase ASCII names containing letters, digits, and
underscores are portable across the supported filesystems.

## Import declarations

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

An import makes declarations from another module available in the importing
scope. Module names in imports are fully qualified; they are not resolved
relative to the importing module.

The order of import declarations does not affect their meaning. Importing the
same module more than once is permitted. The compiler determines how a
qualified name is located on its module search paths.

### Ordinary imports

An ordinary import makes both the module name and its declarations available:

```d
module application;

import geometry.matrix;

extern(C) int main()
{
    Matrix value;
    geometry.matrix.reset(value);
    return 0;
}
```

Declarations in the current lexical scope are considered before declarations
introduced by imports. If the import lookup finds equally applicable
declarations with the same name, the reference is ambiguous and must be
qualified or explicitly aliased.

Given:

```d
module first;
int value();
```

and:

```d
module second;
int value();
```

the importing module qualifies the desired declaration:

```d
module application;

import first;
import second;

int selected()
{
    return first.value();
}
```

### Static imports

A static import requires references to use the fully qualified module name:

```d
static import geometry.matrix;

void clear(geometry.matrix.Matrix* value)
{
    geometry.matrix.reset(*value);
}
```

The unqualified name `reset` is not introduced by this import.

### Renamed imports

A module alias supplies a local name for the imported module:

```d
import matrix = geometry.matrix;

void clear(matrix.Matrix* value)
{
    matrix.reset(*value);
}
```

References use the alias rather than the original qualified module name in that
scope.

### Selective imports

A selective import introduces only the listed declarations:

```d
import geometry.matrix : Matrix, reset;

void clear(Matrix* value)
{
    reset(*value);
}
```

An imported declaration may be renamed:

```d
import geometry.matrix : Matrix, clear = reset;

void clearMatrix(Matrix* value)
{
    clear(*value);
}
```

A module alias and selective bindings may be combined:

```d
import matrix = geometry.matrix : Matrix, clear = reset;
```

Here `matrix` names the module, `Matrix` is introduced in the current scope,
and `clear` names `geometry.matrix.reset`.

`static import` is not combined with a selective import.

### Scoped imports

An import declaration may appear in a local scope. Its names are visible from
the declaration to the end of that scope:

```d
int calculate()
{
    import arithmetic.checked : add;
    return add(20, 22);
}
```

A local import cannot be forward referenced. Imports in an unrelated scope do
not participate in lookup.

## Import visibility

An import is private unless declared `public`.

A private import is usable by the importing module but is not re-exported:

```d
module facade;

private import implementation;
```

A module which imports `facade` does not thereby gain unqualified access to
declarations from `implementation`.

A public import re-exports the imported module's visible declarations:

```d
module geometry;

public import geometry.matrix;
public import geometry.vector;
```

A module importing `geometry` may use the re-exported declarations. Public
imports can therefore provide a stable facade over a collection of modules.

Visibility affects re-export, not the initialization or compilation order of a
module.

## Name lookup

For an unqualified name, lookup first searches lexical declarations from the
innermost scope outward. If no declaration is found, it searches imports which
are visible in those scopes.

Lookup stops at the first phase which produces a match. Multiple matches in the
same phase are ambiguous. A qualified name or an explicit alias resolves the
ambiguity.

A leading dot starts lookup at module scope:

```d
enum defaultCode = 1;

extern(C) int main()
{
    int defaultCode = 5;
    return defaultCode == 5 && .defaultCode == 1 ? 0 : 1;
}
```

## Cyclic imports

Modules may import each other. A cycle in the import graph does not establish a
runtime execution order.

For example, `node` may import a declaration from `visitor` while `visitor`
imports the `Node` type:

```d
module node;

import visitor : visit;

struct Node
{
    int value;
}

int accept(Node* node)
{
    return visit(node);
}
```

```d
module visitor;

import node : Node;

int visit(Node* node)
{
    return node.value;
}
```

Each declaration must still be semantically valid when the modules are
compiled.

## Separate compilation

Each module may be compiled independently. Imported declarations provide the
types and symbol identities needed by the importing module; definitions needed
at link time are supplied by the separately compiled module or a foreign
library.

The order in which modules are passed to the compiler does not change their
language semantics. Linker behavior, library search paths, and the physical
mapping of module names to files are toolchain concerns.
