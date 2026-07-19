// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/com_interface_rejected.d(12): Error: COM interfaces are not supported in Laser-D
---
*/

// IUnknown is the name-based root from which the D frontend derives COM
// interface and COM class behavior.
interface IUnknown
{
    int QueryInterface();
    uint AddRef();
    uint Release();
}
