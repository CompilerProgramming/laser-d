// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/scope_success_failure_rejected.d(13): Error: `scope(success)` is not supported in Laser-D; use `scope(exit)` for deterministic cleanup
laser-d/scope_success_failure_rejected.d(16): Error: `scope(failure)` is not supported in Laser-D because D exception handling is disabled
---
*/

void rejectedScopeGuards()
{
    scope(success)
    {
    }
    scope(failure)
    {
    }
}
