// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/mixin_template_restrictions_rejected.d(26): Error: struct destructors are not supported in Laser-D
laser-d/mixin_template_restrictions_rejected.d(40): Error: mixin `mixin_template_restrictions_rejected.WithDestructor.DestructorInjection!()` error instantiating
laser-d/mixin_template_restrictions_rejected.d(33): Error: struct postblit constructors are not supported in Laser-D
laser-d/mixin_template_restrictions_rejected.d(45): Error: mixin `mixin_template_restrictions_rejected.WithPostblit.PostblitInjection!()` error instantiating
---
*/

// Template mixins inject already parsed declarations into another scope, so
// they are the most direct way a rejected declaration could reach an aggregate
// without being written there. Injected declarations remain subject to every
// Laser-D restriction, and a struct receiving them does not acquire a
// destructor or a postblit.
//
// Declarations rejected while parsing, such as `static this` and `@property`,
// are rejected inside a mixin-template body whether or not it is ever mixed in
// and are covered by module_lifecycle_rejected.d and
// property_functions_rejected.d.

mixin template DestructorInjection()
{
    ~this()
    {
    }
}

mixin template PostblitInjection()
{
    this(this)
    {
    }
}

struct WithDestructor
{
    mixin DestructorInjection;
}

struct WithPostblit
{
    mixin PostblitInjection;
}
