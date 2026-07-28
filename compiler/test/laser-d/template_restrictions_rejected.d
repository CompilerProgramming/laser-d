// TEST_MODE: fail_compilation

/*
TEST_OUTPUT:
---
laser-d/template_restrictions_rejected.d(30): Error: `new` expressions are not supported in Laser-D because implicit allocation is disabled
laser-d/template_restrictions_rejected.d(51): Error: template instance `template_restrictions_rejected.AllocatingTemplate!int` error instantiating
laser-d/template_restrictions_rejected.d(36): Error: array concatenation is not supported in Laser-D
laser-d/template_restrictions_rejected.d(55): Error: template instance `template_restrictions_rejected.concatenateInTemplate!int` error instantiating
laser-d/template_restrictions_rejected.d(41): Error: capturing delegates are not supported in Laser-D
laser-d/template_restrictions_rejected.d(39):        captured variable `captured` declared here
laser-d/template_restrictions_rejected.d(57): Error: template instance `template_restrictions_rejected.capturingDelegateInTemplate!int` error instantiating
laser-d/template_restrictions_rejected.d(46): Error: array append is not supported in Laser-D
laser-d/template_restrictions_rejected.d(59): Error: template instance `template_restrictions_rejected.appendInTemplate!int` error instantiating
---
*/

// Templates are not a second language mode. A construct rejected during
// semantic analysis stays rejected when it reaches the compiler through a
// template instantiation rather than through ordinary code. Constructs
// rejected while parsing, such as `assert`, associative-array types, and class
// declarations, are covered by their own tests and cannot reach a template
// body at all. String mixins in templates are covered by
// template_string_mixin_rejected.d.

struct AllocatingTemplate(T)
{
    void allocate()
    {
        auto instance = new T;
    }
}

void concatenateInTemplate(T)(T[] left, T[] right)
{
    auto joined = left ~ right;
}

auto capturingDelegateInTemplate(T)(T captured)
{
    return () => captured;
}

void appendInTemplate(T)(T[] destination, T element)
{
    destination ~= element;
}

void instantiate()
{
    AllocatingTemplate!int allocating;
    allocating.allocate();

    int[] values;
    concatenateInTemplate(values, values);

    auto captured = capturingDelegateInTemplate(1);

    appendInTemplate(values, 1);
}
