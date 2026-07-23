---
title: Error handling
status: restricted
source: ../spec/errors.dd
---

# Error Handling

> **Laser-D:**
>
> D exception handling is not supported. Source `try`, `catch`, `finally`, and `throw` statements are rejected. Programs represent and
> propagate errors explicitly, for example through return values or C APIs.
> `scope(exit)` is the supported deterministic-cleanup construct.

## Runtime Assertions

> **Rejected in Laser-D:**
>
> Runtime `assert` expressions are rejected. Their failure
> paths require D runtime hooks and their removal under release settings would
> make program behavior depend on compiler configuration. Use explicit
> conditions and explicit error propagation. The compiler-only
> `static assert` declaration remains supported.

> I came I coded I crashed.
>
> — Julius C'ster

src="../images/dman-error.jpg" border="0" align="right" alt="Erroneous D-Man" height="200"

All programs have to deal with errors. Errors are unexpected conditions that
are not part of the normal operation of a program. Examples of common errors
are:

- Out of memory.
- Out of disk space.
- Invalid file name.
- Attempting to write to a read-only file.
- Attempting to read a non-existent file.
- Requesting a system service that is not supported.

## <a id="the_error_handling_problem"></a>The Error Handling Problem

The traditional C way of detecting and reporting errors is not traditional, it is ad-hoc and varies from function to function, including:

- Returning a NULL pointer.
- Returning a 0 value.
- Returning a non-zero error code.
- Requiring errno to be checked.
- Requiring that a function be called to check if the previous function failed.

To deal with these possible errors, tedious error handling code must be added
to each function call. If an error happened, code must be written to recover
from the error, and the error must be reported to the user in some user friendly
fashion. If an error cannot be handled locally, it must be explicitly
propagated back to its caller.
The long list of errno values needs to be converted into appropriate
text to be displayed. Adding all the code to do this can consume a large part
of the time spent coding a project - and still, if a new errno value is added
to the runtime system, the old code can not properly display a meaningful
error message.

Good error handling code tends to clutter up what otherwise would be a neat
and clean looking implementation.

Even worse, good error handling code is itself error prone, tends to be the
least tested (and therefore buggy) part of the project, and is frequently
simply omitted. The end result is likely a "blue screen of death" as the
program failed to deal with some unanticipated error.

Quick and dirty programs are not worth writing tedious error handling code
for, and so such utilities tend to be like using a table saw with no
blade guards.

What's needed is an error handling philosophy and methodology such that:

- It is standardized - consistent usage makes it more useful.
- The result is reasonable even if the programmer fails to check for errors.
- Old code can be reused with new code without having to modify the old code to be compatible with new error types.
- No errors get inadvertently ignored.
- ' utilities can be written that still correctly handle errors.
- It is easy to make the error handling source code look good.

## <a id="the_d_error_handling_solution"></a>The D Error Handling Solution

Let's first make some observations and assumptions about errors:

- Errors are not part of the normal flow of a program. Errors are exceptional, unusual, and unexpected.
- Because errors are unusual, execution of error handling code is not performance critical.
- The normal flow of program logic is performance critical.
- All errors must be dealt with in some way, either by code explicitly written to handle them, or by some system default handling.
- The code that detects an error knows more about the error than the code that must recover from the error.

The solution is to use exception handling to report errors. All
errors are objects derived from the abstract class [`Error`](https://dlang.org/phobos/object.md#.Error). `Error`
has a pure virtual function called toString() which produces a `string`
with a human readable description of the error.

If code detects an error like "out of memory, " then an `Error` is thrown
with a message saying "Out of memory". The function call stack is unwound, looking for a handler for the Error.
[Finally blocks](statement.md#TryStatement)
are executed as the
stack is unwound. If an error handler is found, execution resumes there. If
not, the default Error handler is run, which displays the message and
terminates the program.

How does this meet our criteria?

**It is standardized - consistent usage makes it more useful.**

        : This is the D way, and is used consistently in the D runtime library and examples.

**The result is reasonable result even if the programmer fails to check for errors.**

        : If no catch handlers are there for the errors, then the program gracefully exits through the default error handler with an appropriate message.

**Old code can be reused with new code without having to modify the old code to be compatible with new error types.**

        : Old code can decide to catch all errors, or only specific ones, propagating the rest upwards. In any case, there is no more need to correlate error numbers with messages, the correct message is always supplied.

**No errors get inadvertently ignored.**

        : Error exceptions get handled one way or another. There is nothing like a NULL pointer return indicating an error, followed by trying to use that NULL pointer.

**'Quick and dirty' utilities can be written that still correctly handle errors.**

        : Quick and dirty code need not write any error handling code at all, and don't need to check for errors. The errors will be caught, an appropriate message displayed, and the program gracefully shut down all by default.

**It is easy to make the error handling source code look good.**

        : The try/catch/finally statements look a lot nicer than endless `if (error) goto errorhandler;` statements.

How does this meet our assumptions about errors?

**Errors are not part of the normal flow of a program. Errors are exceptional, unusual, and unexpected.**

        : D exception handling fits right in with that.

**Because errors are unusual, execution of error handling code is not performance critical.**

        : Exception handling stack unwinding is a relatively slow process.

**The normal flow of program logic is performance critical.**

        : Since the normal flow code does not have to check every function call for error returns, it can be realistically faster to use exception handling for the errors.

**All errors must be dealt with in some way, either by code explicitly written to handle them, or by some system default handling.**

        : If there's no handler for a particular error, it is handled by the runtime library default handler. If an error is ignored, it is because the programmer specifically added code to ignore an error, which presumably means it was intentional.

**The code that detects an error knows more about the error than the code that must recover from the error.**

        : There is no more need to translate error codes into human readable strings, the correct string is generated by the error detection code, not the error recovery code. This also leads to consistent error messages for the same error between applications.

Using exceptions to handle errors leads to another issue - how to write
exception safe programs. [Here's how](https://dlang.org/articles/exception-safe.html).
