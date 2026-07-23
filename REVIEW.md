# Review notes

## Fixed-array initializer expressions

During the ordinary control-flow audit, `int[4] values = [1, 2, 3, 4];` was
rejected as a dynamic array literal. The arrays specification review confirmed
that context-typed literals should initialize fixed storage without allocation.
`FEATURE_STATUS.md` records the current blanket rejection as an implementation
defect. Positive conformance coverage should be added when that defect is fixed.

## Symbolic fixed-array dimensions

During the type-qualifier documentation validation, `enum n = 3; alias A =
int[n];` was rejected as an associative-array type. Literal dimensions and some
compound CTFE dimensions already work, but a manifest identifier is currently
misclassified before its value establishes a fixed-array dimension. The arrays
specification requires integral compile-time dimension expressions, so this is
an implementation defect. Positive coverage for manifest and other symbolic
dimensions should accompany the fix.

## ImportC variadic declarations

The variadic-function audit confirmed Laser-D-authored `extern(C)` variadic
definitions, function pointers, and calls. Adding a variadic prototype to the
minimal ImportC fixture, however, made ImportC request
`__importc_builtins.d`; that module is not present on the fixture's configured
import paths. The prototype was therefore removed from this change rather than
masking the dependency with a test-only stub. ImportC variadic declarations
need dedicated coverage when the minimal ImportC environment provides the
compiler's builtins module.

## Front-end conformance review (2026-07-23)

A full verification pass was made over the language front-end against the
documentation and the `compiler/test/laser-d` suite.

### Method

The `dmd.exe` at the repository root was stale: it predated `parse.d`,
`funcsem.d`, `expressionsem.d`, and `dsymbolsem.d`, and produced misleading
results (for example, `@disable void f();` compiled cleanly). The front-end was
rebuilt from current source with an unmodified host compiler
(`compiler/src/build.d` cannot be compiled by Laser-D itself, since it uses
`__gshared`, associative arrays, and `try`/`catch`). The official runner was
then used:

```console
dmd -i -run run.d laser-d HOST_DMD=<host-dmd>
```

All 190 tests pass. The harness was confirmed to validate diagnostics rather
than only exit codes by corrupting one expected message and observing an exact
message-and-line diff failure. Roughly forty additional probes were run
directly against the freshly built compiler.

### Conformance result

Implementation, tests, and the DESIGN/FEATURE_STATUS decisions agree. The
restrictions are implemented as explicit `Laser-D`-tagged parse and semantic
checks, independent of BetterC, and apply to all D source including imported
modules (the full druntime `object.d` is itself rejected, which is why a minimal
`object.d` is provided). ImportC (`.i`) input is correctly exempt via the
`filetype == FileType.c` guard: C mutable globals, `long double`, and C `const`
are accepted, while the same forms are rejected in Laser-D source. The
mutable-static-storage rule is precisely scoped — mutable locals, parameters,
`ref` parameters, instance fields, local fixed arrays, and heap pointers all
remain legal; only mutable global or static storage is rejected.

### Findings (no fixes applied)

1. **Fixed-array literal defect (functional, already tracked).** `int[4] x =
   [1, 2, 3, 4];` for a local or otherwise mutable array is rejected as a
   dynamic array literal, and `int[n]` with a manifest `n` is misclassified as
   an associative array. Both reproduce as recorded in the earlier notes above.
   One refinement: an `immutable` static array literal
   (`immutable int[4] v = [1, 2, 3, 4];`) does compile, so the current
   FEATURE_STATUS wording ("the current frontend rejects context-typed
   literals") is broader than the actual behavior — the breakage is specific to
   non-immutable or local storage. `static_arrays_and_slices_accepted.d`
   sidesteps the defect with element-by-element assignment, so positive
   coverage of the literal form is still missing.

2. **DESIGN.md structural defect (documentation).** The `## Lexical analysis`
   heading is empty; its actual body and the mutable-static-storage paragraph
   are misplaced under `## Vector extensions`. There is no
   `## Mutable static storage` heading even though FEATURE_STATUS treats it as a
   first-class cross-cutting rule. This appears to be an editing accident.

3. **Hidden test coupling (fragile).**
   `importc_upstream_compilable_cimports2.i` imports `imports.cimports2a` and
   `imports.cimports2b`, which were not copied into `compiler/test/laser-d`. It
   passes only because its `REQUIRED_ARGS: -Icompilable` resolves to the
   upstream `compiler/test/compilable/imports/` fixtures still present in the
   tree. It would break silently if the upstream tests were pruned; the fixtures
   should be copied locally or the dependency documented.

4. **Grey areas silently accepted (untested).** `pragma(inline)`,
   `pragma(mangle)`, `debug`/`debug(x)`, `deprecated`, and `align` currently
   pass through with no decision and no test. This is consistent with their
   Undecided status in FEATURE_STATUS, but until decided they are not held to
   the "make consequential behavior visible" principle.

5. **Workflow hazard (not a repository defect).** The stale root `dmd.exe` is
   gitignored and will not ship, but it is what an unaware user would run and it
   silently yields wrong results. Rebuilding or removing it as part of the
   normal workflow avoids the trap. Relatedly, Laser-D is intentionally not
   self-hosting (it cannot compile `build.d`), which is consistent with the
   project goals but worth stating explicitly.

Overall the design-to-specification-to-test-to-implementation chain is
consistent and disciplined. The one genuinely misleading trap encountered was
the stale binary, which is a workspace artifact rather than a source problem.
