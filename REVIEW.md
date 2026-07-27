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

## Compiler and library review (2026-07-27)

A second verification pass covering the front-end, the Markdown specification,
and the new CMake-built `library/` tree.

### Method

`laserd.exe` was newer than every compiler source file, so the stale-binary
hazard recorded in the previous review is resolved and no rebuild was required.
Everything below was run against that executable.

| Suite | Result |
| --- | --- |
| `compiler/test/laser-d`, 206 tests (previously 190) | all pass, exact message and line matching |
| CMake configure, build, `ctest` (7 tests), `package` | all pass, package produced |
| `spec-markdown` index coverage and local links | complete, no broken links |
| Packaged `laserd` plus `import/` and `lib/` compiling and running a program | runs correctly |

`tools/check_markdown_docs.py` could not be executed directly because Python is
not installed on the review machine (only the Windows Store stub is present).
Its index, heading, front-matter, and link checks were reimplemented to run the
equivalent validation.

### Resolved since the previous review

Both implementation defects are fixed, and the intended distinction is
preserved: `int[4] v = [1, 2, 3, 4];` and `enum n = 3; int[n] a;` are now
accepted, while `int[] d = [1, 2, 3];` is still rejected as a dynamic array
literal. The compiler is now named `laserd` to distinguish it from the
bootstrap `dmd`, `-m32` and `-m32mscoff` are rejected, and every library module
has at least one CTest.

Two language changes landed consistently. `const` is now a restricted
qualifier — `const` data and parameters are accepted while postfix `const`
member-function qualifiers are rejected — and DESIGN.md describes exactly that
boundary. The reversal of C++ interoperability, from supported free functions to
wholesale rejection of `extern(C++)`, is propagated across DESIGN.md,
FEATURE_STATUS.md, the removed Markdown chapter, and the tests. The library's
own Laser-D sources contain no rejected constructs.

### Findings (no fixes applied)

1. **Some documented rejections are runtime-gated rather than language-gated.**
   `spec-markdown/d-compatibility.md` lists `.reserve` and implicit-result array
   operations alongside `.dup`, `.idup`, and `.capacity` as unavailable, but only
   the latter three are enforced in the front end. Appending a `reserve`
   declaration to `object.d` re-enables it, whereas `.dup` remains rejected
   regardless of the runtime. `.sort` and `c[] = a[] + b[];` behave the same way
   and surface upstream diagnostics rather than Laser-D decisions: `.sort`
   suggests importing `std.algorithm`, which does not exist in Laser-D, and array
   operations report an undefined `_arrayOp` identifier. This conflicts with the
   maintenance rule that a language decision must not be inferred from current
   implementation behavior, and these forms should either gain explicit
   front-end checks or be reclassified as runtime-dependent rather than decided.

   **Response (2026-07-27): resolved with the boundaries separated.**
   `.dup`, `.idup`, and `.capacity` remain compiler-recognized properties with
   explicit front-end rejection. D's `object.reserve` is instead a GC-backed
   runtime function reached through UFCS; the compatibility specification,
   DESIGN.md, and FEATURE_STATUS.md now describe that standard facility as
   omitted while preserving user-defined, non-GC `reserve` functions.

   A genuinely implicit-result expression such as `return a[] + b[];` was
   already rejected by the front end and now has a dedicated conformance test.
   The destination-backed `c[] = a[] + b[];` form need not allocate and remains
   the distinct Undecided “Vectorized array expressions” entry in
   FEATURE_STATUS.md; its current dependency on `object._arrayOp` is not treated
   as a rejection. `.sort` is likewise an ordinary UFCS/library call rather
   than a reserved array property. User-defined implementations remain valid,
   and the compiler no longer suggests importing the unavailable
   `std.algorithm` module when lookup fails.

2. **DESIGN.md structure has degraded further.** The empty `## Lexical analysis`
   heading and its orphaned body under `## Vector extensions` are unchanged from
   the previous review. In addition, `## Expressions` is now the final level-two
   heading in the file, so `### Modules`, `### C standard library bindings`,
   `### Synchronization`, and `### Specification organization` are all nested
   beneath it. The new library sections were appended at the wrong heading level.

   **Response (2026-07-27): resolved.** The lexical-analysis text now appears
   directly beneath its heading, mutable static storage and native threading
   have their own section, and every major topic following Expressions has
   been restored to level two. The document hierarchy no longer nests modules,
   libraries, synchronization, or specification organization beneath
   Expressions.

3. **The feature ledger covers the library inconsistently.** `core.stdc`,
   `std.traits`, and `laserd.hash` have FEATURE_STATUS rows, while
   `laserd.memory`, `laserd.thread`, `laserd.system`, and the
   `laserd.foundation` modules do not, although all of them are documented in
   DESIGN.md and `library/README.md`. The boundary between language ledger and
   library documentation should be drawn deliberately in one direction.

   **Response (2026-07-27): resolved.** FEATURE_STATUS.md deliberately covers
   the shipped public library as well as language features. It now has rows for
   `laserd.memory`, the reviewed `laserd.foundation` utility and lifecycle
   subset, `laserd.thread`, and `laserd.system`, with their ownership and scope
   boundaries and corresponding integration tests.

4. **Concurrency ships without a documented memory model.** The library now
   provides threads, mutexes, and condition variables, but the language rejects
   `shared`, offers no atomics, and forbids mutable static storage.
   FEATURE_STATUS still justifies the `shared` rejection on the grounds that C
   threading and atomics remain reachable through ImportC, which no longer
   describes the situation: `laserd.thread` is `extern(C)` Laser-D, not ImportC.
   `library/test/thread_sync.d` shares a struct of plain `int` fields between
   threads through a stack pointer. This is safe in practice because nsync's
   opaque `extern(C)` calls act as compiler barriers, but no document states
   that, and there is no guidance for programs that have threads without
   `shared`, atomics, or mutable statics.

   **Response (2026-07-27): resolved.** `laserd.thread`, DESIGN.md, and
   `library/README.md` now define the library synchronization contract.
   Successful exclusive and reader mutex acquisitions have acquire semantics,
   and releases have release semantics; a release happens before a later
   successful acquisition of the same mutex. Condition waits release and
   reacquire the mutex with those semantics, while signal and broadcast only
   wake waiters and do not independently publish unprotected data. Thread start
   publishes initialized argument data to the callback, and a completed join
   makes the callback's preceding writes visible to the joining thread.
   Programs must protect every conflicting concurrent access with these
   mutexes or another explicitly reviewed foreign synchronization API.

   FEATURE_STATUS.md remains correct as a language-feature ledger:
   `shared`, `__gshared`, `synchronized`, and language-level atomics remain
   rejected. The documented guarantees belong to the `laserd.thread` foreign
   library facade and do not reintroduce D language-level threading support.

5. **The Markdown check is weaker than DESIGN.md claims.**
   `check_markdown_docs.py` validates front matter only when it is present, so
   chapters without it are skipped silently. Ten of the twenty-two chapters
   (`arrays`, `attribute`, `const3`, `d-compatibility`, `declaration`, `enum`,
   `function`, `module`, `struct`, and `type`) currently have none, so the stated
   verification of chapter metadata applies only to the twelve already
   converted, and nothing reports a chapter that was missed.

   **Response (2026-07-27): resolved.** All ten chapters now have `title`,
   `status`, and `source` front matter consistent with their current feature
   classifications. `check_markdown_docs.py` now reports missing front matter
   as an error instead of conditionally validating metadata only when present.

6. **Windows packaging omits a link requirement.** The packaged
   `laserd_rpmalloc.lib` depends on `advapi32.lib` for `OpenProcessToken`,
   `AdjustTokenPrivileges`, and `LookupPrivilegeValueA`. The CMake build supplies
   this, but a program linked directly against the package with `laserd` fails
   with three unresolved externals until `advapi32.lib` is added. The
   requirement is not documented for consumers who do not use CMake.

   **Response (2026-07-27): resolved.** README.md and `library/README.md` now
   show that direct Windows links using `laserd_rpmalloc.lib` must also include
   `advapi32.lib`. They note that the dependency also applies through
   `laserd.hash` and Foundation, document Foundation's additional `user32.lib`
   and `shell32.lib` requirements, and distinguish direct invocation from the
   repository CMake build that propagates the platform libraries automatically.

7. **Carried forward from the previous review.**
   `importc_upstream_compilable_cimports2.i` still resolves its fixtures from the
   upstream `compiler/test/compilable/imports/` directory through
   `-Icompilable`. The grey areas `pragma(inline)`, `pragma(mangle)`, `debug`,
   `deprecated`, and `align` remain silently accepted, though bookkeeping
   improved with an explicit undecided entry for statement pragmas. The `dist/`
   directory holds a stale extracted package; like the earlier stale binary it is
   gitignored and is a workspace artifact rather than a repository defect.

   **Response (2026-07-27): resolved.**
   `importc_upstream_compilable_cimports2.i` now resolves byte-identical
   `cimports2a.i` and `cimports2b.i` fixtures from
   `compiler/test/laser-d/extra-files/imports` and no longer uses the upstream
   `compilable/imports` tree. FEATURE_STATUS.md already tracked `debug`,
   `deprecated`, and `align` independently; it now also has distinct Undecided
   entries for `pragma(inline)` and `pragma(mangle)`. DESIGN.md states that
   parser acceptance of these pragma families is not normative.

   The ignored stale extracted package and CPack staging directories were
   removed from `dist/`. The generated ZIP archive was retained; the deleted
   directories can be recreated by running the package target.

### Assessment

The project is in materially better shape than at the previous review: both
recorded defects are fixed, the conformance suite has grown, and the CMake
library with its vendored C dependencies builds, tests, packages, and runs
end to end. The C++ removal and the `const` addition both demonstrate the
documentation, specification, test, and implementation chain working as
intended.

Finding 1 is the substantive one. The boundary between constructs Laser-D
rejects and constructs the minimal runtime merely fails to provide is currently
blurred in the compatibility document, which is precisely the accidental
guarantee the project's robustness principle warns against. Finding 4 is the
strategic one: the library has outgrown the language's concurrency rationale,
and the documentation has not yet caught up.
