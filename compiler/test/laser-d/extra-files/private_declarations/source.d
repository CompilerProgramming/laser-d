module private_declarations.source;

private
{
    enum moduleValue = 7;

    template increment(int value)
    {
        enum increment = value + 1;
    }

    struct Hidden
    {
        int value;
    }
}

enum publicValue = increment!moduleValue + 15;
enum hiddenSize = Hidden.sizeof;

struct Vault
{
    private
    {
        int value;

        this(int value)
        {
            this.value = value;
        }

        int valueInsideModule()
        {
            return value;
        }
    }

    int valueForCaller()
    {
        return value;
    }
}

Vault make(int value)
{
    return Vault(value);
}

int read(Vault value)
{
    return value.valueInsideModule();
}

int defaultConstructionWorks()
{
    Vault value;
    Vault initialized = Vault.init;
    return value.valueInsideModule() + initialized.valueInsideModule();
}

private:

enum trailingPrivateValue = 41;
