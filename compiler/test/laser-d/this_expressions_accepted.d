// TEST_MODE: runnable

int readCopy(Counter counter)
{
    return counter.value;
}

struct Counter
{
    int value;

    alias ThisType = typeof(this);
    static assert(is(ThisType == Counter));

    this(int initial)
    {
        this.value = initial;
    }

    Counter increment()
    {
        ++this.value;
        return this;
    }

    Counter* address()
    {
        return &this;
    }

    int read()
    {
        return this.value;
    }

    int receiverSize(this Receiver)()
    {
        static assert(is(Receiver == Counter));
        return Receiver.sizeof;
    }

    int immutableReceiverSize(this Receiver)() immutable
    {
        static assert(is(Receiver == immutable(Counter)));
        return Receiver.sizeof;
    }

    int passByValue()
    {
        return readCopy(this);
    }

    int delegateCall()
    {
        int delegate() reader = &this.read;
        return reader();
    }
}

union Storage
{
    int signedValue;
    uint unsignedValue;

    uint readBits()
    {
        return this.unsignedValue;
    }
}

extern(C) int main()
{
    Counter counter = Counter(41);
    Counter copied = counter.increment();

    if (counter.value != 42 || copied.value != 42)
        return 1;
    if (counter.address() != &counter)
        return 2;
    if (counter.receiverSize() != Counter.sizeof)
        return 3;
    if (counter.delegateCall() != 42)
        return 4;
    if (counter.passByValue() != 42)
        return 5;

    immutable Counter immutableCounter = Counter(42);
    if (immutableCounter.immutableReceiverSize() != Counter.sizeof)
        return 6;

    Storage storage;
    storage.unsignedValue = 42;
    return storage.readBits() == 42 ? 0 : 7;
}
