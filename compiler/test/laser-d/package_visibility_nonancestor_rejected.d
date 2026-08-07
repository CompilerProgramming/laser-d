// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/package_visibility_nonancestor_rejected.d(12): Error: visibility attribute `package(unrelated)` does not bind to one of ancestor packages of module `package_visibility.inner.invalid_boundary`
---
*/

module package_visibility.inner.invalid_boundary;

package(unrelated) enum invalidBoundary = 31;
