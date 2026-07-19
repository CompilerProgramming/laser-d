module template_emission;

struct Value
{
}

void invoke(alias operation)(Value value)
{
    operation(value);
}

struct Wrapper
{
    static void apply(Value value)
    {
        invoke!(nested => nested)(value);
    }
}
