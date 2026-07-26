# Laser-D language tests

This directory contains the executable language specification for Laser-D.
Run the complete suite from `compiler/test` with:

```console
./run.d laser-d
```

The equivalent long target name is `run_laser_d_tests`. An individual test can
be run by passing its path, for example:

```console
./run.d laser-d/betterc_default.d
```

Every `.d`, `.c`, or `.i` test in this directory must declare one of these modes:

```d
// TEST_MODE: compilable
// TEST_MODE: fail_compilation
// TEST_MODE: runnable
```

Use `compilable` for accepted syntax and semantic behavior,
`fail_compilation` for rejected language features, and `runnable` when code
generation, linking, or execution is part of the language guarantee. A
negative test must include `TEST_OUTPUT` that demonstrates rejection for the
intended reason.

Keep each test focused on one feature or one closely related boundary. Update
the applicable source under `spec-markdown/`, `DESIGN.md`, and
`FEATURE_STATUS.md` when
a test records a new or changed language decision.

Files named `importc_upstream_*` are passing preprocessed ImportC tests copied
from the corresponding upstream `compilable`, `runnable`, or
`fail_compilation` category. Their category prefix avoids collisions in this
flat directory. Runner metadata, expected source paths and module names, and
fixture paths are adjusted only as required by their Laser-D location.

Files named `upstream_compilable_*` are D-language regression tests adopted
from the corresponding upstream `compilable` category after their exercised
features have been checked against Laser-D's documented subset. The source is
kept materially equivalent, with Laser-D `TEST_MODE` metadata and provenance
comments added.
