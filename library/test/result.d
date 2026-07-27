import core.stdc.stdlib : EXIT_FAILURE, EXIT_SUCCESS;
import laserd.result : Optional, Result;

private enum ParseError
{
    none,
    invalidInput,
    outOfRange,
}

private struct Big
{
    long a;
    long b;
    long c;
    long d;
}

private Result!(int, ParseError) parsePositive(int raw)
{
    if (raw < 0)
        return Result!(int, ParseError).err(ParseError.invalidInput);
    if (raw > 1000)
        return Result!(int, ParseError).err(ParseError.outOfRange);
    return Result!(int, ParseError).ok(raw);
}

private Result!(void, ParseError) validate(int raw)
{
    if (raw < 0)
        return Result!(void, ParseError).err(ParseError.invalidInput);
    return Result!(void, ParseError).ok();
}

private int doubled(int value)
{
    return value * 2;
}

private int addContext(void* context, int value)
{
    return value + *cast(int*) context;
}

// Overlapping error storage does not enlarge a result beyond its value type
// plus its discriminant.
static assert(Result!(int, ParseError).sizeof <= 2 * int.sizeof);
static assert(Result!(Big, ParseError).sizeof < Big.sizeof + Big.sizeof);
static assert(Optional!int.sizeof >= int.sizeof);

// A default-initialized optional is empty and a default-initialized result is
// not successful.
static assert(!Optional!int.init.has());
static assert(!Result!(int, ParseError).init.isOk());

extern(C) int main()
{
    // Optional: present and absent.
    auto present = Optional!int.some(41);
    auto absent = Optional!int.none();

    if (!present.has() || absent.has())
        return EXIT_FAILURE;
    if (present.orElse(0) != 41 || absent.orElse(7) != 7)
        return EXIT_FAILURE;
    if (!present || absent)
        return EXIT_FAILURE;

    int* presentPointer = present.ptr();
    if (presentPointer is null || *presentPointer != 41)
        return EXIT_FAILURE;
    if (absent.ptr() !is null)
        return EXIT_FAILURE;

    // A pointer element type keeps the uniform representation, so a present
    // null pointer is distinguishable from an absent value.
    auto presentNull = Optional!(int*).some(null);
    if (!presentNull.has() || Optional!(int*).none().has())
        return EXIT_FAILURE;

    // Result: success and both error paths.
    auto good = parsePositive(12);
    auto negative = parsePositive(-1);
    auto excessive = parsePositive(4000);

    if (!good.isOk() || negative.isOk() || excessive.isOk())
        return EXIT_FAILURE;
    if (!good || negative)
        return EXIT_FAILURE;
    if (good.valueOr(0) != 12)
        return EXIT_FAILURE;
    if (negative.errorOr(ParseError.none) != ParseError.invalidInput)
        return EXIT_FAILURE;
    if (excessive.errorOr(ParseError.none) != ParseError.outOfRange)
        return EXIT_FAILURE;

    // Accessors are total: reading the absent side yields the fallback.
    if (negative.valueOr(-5) != -5)
        return EXIT_FAILURE;
    if (good.errorOr(ParseError.none) != ParseError.none)
        return EXIT_FAILURE;

    // Pointer accessors are null on the side which carries no data.
    int* value = good.value();
    if (value is null || *value != 12)
        return EXIT_FAILURE;
    if (good.error() !is null)
        return EXIT_FAILURE;
    ParseError* error = negative.error();
    if (error is null || *error != ParseError.invalidInput)
        return EXIT_FAILURE;
    if (negative.value() !is null)
        return EXIT_FAILURE;

    // Mapping uses ordinary function pointers, since Laser-D has no capturing
    // delegates. An error is forwarded unchanged.
    auto mapped = good.mapValue(&doubled);
    if (!mapped.isOk() || mapped.valueOr(0) != 24)
        return EXIT_FAILURE;
    auto mappedError = negative.mapValue(&doubled);
    if (mappedError.isOk()
        || mappedError.errorOr(ParseError.none) != ParseError.invalidInput)
        return EXIT_FAILURE;

    int addend = 100;
    auto withContext = good.mapValueContext(&addend, &addContext);
    if (!withContext.isOk() || withContext.valueOr(0) != 112)
        return EXIT_FAILURE;

    // A void result reports success or failure without carrying a value.
    auto validated = validate(3);
    auto rejected = validate(-3);
    if (!validated.isOk() || rejected.isOk())
        return EXIT_FAILURE;
    if (rejected.errorOr(ParseError.none) != ParseError.invalidInput)
        return EXIT_FAILURE;
    if (validated.error() !is null)
        return EXIT_FAILURE;

    // A larger value type round-trips through overlapping storage.
    Big big;
    big.a = 1;
    big.d = 4;
    auto bigResult = Result!(Big, ParseError).ok(big);
    if (!bigResult.isOk())
        return EXIT_FAILURE;
    if (bigResult.valueOr(Big.init).a != 1 || bigResult.valueOr(Big.init).d != 4)
        return EXIT_FAILURE;

    // Deterministic cleanup composes with a result-returning call.
    int released = 0;
    {
        scope(exit) released = 1;
        auto scoped = parsePositive(5);
        if (!scoped.isOk())
            return EXIT_FAILURE;
    }
    if (released != 1)
        return EXIT_FAILURE;

    return EXIT_SUCCESS;
}
