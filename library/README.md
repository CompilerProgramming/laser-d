# Laser-D standard library

This directory contains the source modules distributed with Laser-D.

The initial `core.stdc` modules are bindings to the platform C runtime. They
contain ABI types, constants, and `extern(C)` declarations, but no D runtime,
garbage collector, module lifecycle, or hidden initialization.

Only APIs verified by the Laser-D test suite are part of the supported subset.
The modules are derived from the corresponding druntime bindings and adapted
to use only Laser-D language features.

`object.d` is the minimal implicit module distributed with the compiler.
Standard-library integration tests live under `library/test` and are compiled
directly with Laser-D:

```console
generated/linux/release/64/laserd -conf= -Ilibrary -run library/test/core_stdc.d
```

The distribution builder copies `object.d` and the supported modules under
`core/` into its `import/` directory. It deliberately excludes `library/test`.
No library archive is produced while the supported modules contain declarations
only; programs link directly to the platform C runtime.
