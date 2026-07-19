// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/exception_statements_rejected.d(15): Error: `try` is not supported in Laser-D; use `scope(exit)` for deterministic cleanup
laser-d/exception_statements_rejected.d(18): Error: `catch` is not supported in Laser-D because D exception handling is disabled
laser-d/exception_statements_rejected.d(21): Error: `finally` is not supported in Laser-D; use `scope(exit)` for deterministic cleanup
laser-d/exception_statements_rejected.d(25): Error: `throw` is not supported in Laser-D because D exception handling is disabled
---
*/

void rejectedStatements()
{
    try
    {
    }
    catch (Throwable error)
    {
    }
    finally
    {
    }

    throw null;
}
