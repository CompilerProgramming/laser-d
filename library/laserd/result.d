/**
 * Optional and result values for Laser-D.
 *
 * Laser-D has no exceptions, so a fallible operation reports failure as
 * ordinary returned data. `Optional` carries a value which may be absent, and
 * `Result` carries either a value or an error. Both are plain value types: no
 * allocation, no runtime metadata, and no hidden control flow.
 *
 * Every accessor is total. There is no operation which is undefined when the
 * value is absent or the result holds an error, because Laser-D has no runtime
 * assertion to trap such a call. A caller either supplies a fallback with
 * `orElse`, `valueOr`, or `errorOr`, or takes a pointer accessor which is
 * `null` in the states that carry no value.
 *
 * The language cannot require a caller to inspect a result. `@disable` is
 * rejected, so construction cannot be funnelled through a checked path, and
 * destructors are rejected, so an ignored value cannot be detected when it goes
 * out of scope. Total accessors are therefore the enforced property: misuse
 * yields a documented fallback rather than undefined behaviour.
 *
 * The representation is uniform for every element type. A pointer element does
 * not use `null` as an empty representation: a Laser-D pointer is nullable, so
 * a present `null` pointer and an absent value would otherwise be
 * indistinguishable.
 *
 * A pointer returned by `ptr`, `value`, or `error` refers into the storage of
 * the `Optional` or `Result` it was taken from. It remains valid only while
 * that value is alive and unmodified.
 */
module laserd.result;

/**
 * A value which may be absent.
 *
 * The default-initialized state is empty.
 */
struct Optional(T)
{
    private bool present;
    private T storage;

    /// Returns: an `Optional` holding `value`
    static Optional some(T value)
    {
        Optional result;
        result.present = true;
        result.storage = value;
        return result;
    }

    /// Returns: an empty `Optional`
    static Optional none()
    {
        Optional result;
        return result;
    }

    /// Returns: whether a value is present
    bool has()
    {
        return present;
    }

    /// Returns: whether a value is present
    bool opCast(C : bool)()
    {
        return present;
    }

    /// Returns: the value when present, otherwise `fallback`
    T orElse(T fallback)
    {
        return present ? storage : fallback;
    }

    /**
     * Returns: a pointer to the value, or `null` when absent
     *
     * The pointer refers into this `Optional` and does not outlive it.
     */
    T* ptr()
    {
        return present ? &storage : null;
    }
}

/**
 * Either a value of type `T` or an error of type `E`.
 *
 * `T` may be `void` for an operation which either succeeds without producing a
 * value or fails with an error.
 *
 * The default-initialized state holds the default-initialized error.
 */
struct Result(T, E)
{
    private bool succeeded;

    static if (is(T == void))
    {
        private E errStore;

        /// Returns: a successful `Result`
        static Result ok()
        {
            Result result;
            result.succeeded = true;
            return result;
        }
    }
    else
    {
        // Overlapping storage is sound here because Laser-D rejects
        // destructors, postblits, and copy or move constructors, so no union
        // member carries lifecycle behaviour.
        private union
        {
            T okStore;
            E errStore;
        }

        /// Returns: a `Result` holding `value`
        static Result ok(T value)
        {
            Result result;
            result.succeeded = true;
            result.okStore = value;
            return result;
        }

        /// Returns: the value when successful, otherwise `fallback`
        T valueOr(T fallback)
        {
            return succeeded ? okStore : fallback;
        }

        /**
         * Returns: a pointer to the value, or `null` when the result is an error
         *
         * The pointer refers into this `Result` and does not outlive it.
         */
        T* value()
        {
            return succeeded ? &okStore : null;
        }

        /**
         * Applies `transform` to a successful value.
         *
         * `transform` is an ordinary function pointer because Laser-D has no
         * capturing delegates. Use `mapValueContext` when the transformation
         * needs additional state.
         *
         * Returns: the transformed result, or the original error
         */
        Result!(U, E) mapValue(U)(U function(T) transform)
        {
            return succeeded
                ? Result!(U, E).ok(transform(okStore))
                : Result!(U, E).err(errStore);
        }

        /**
         * Applies `transform` to a successful value with explicit context.
         *
         * Returns: the transformed result, or the original error
         */
        Result!(U, E) mapValueContext(U)(
            void* context, U function(void*, T) transform)
        {
            return succeeded
                ? Result!(U, E).ok(transform(context, okStore))
                : Result!(U, E).err(errStore);
        }
    }

    /// Returns: a `Result` holding `error`
    static Result err(E error)
    {
        Result result;
        result.succeeded = false;
        result.errStore = error;
        return result;
    }

    /// Returns: whether the result is successful
    bool isOk()
    {
        return succeeded;
    }

    /// Returns: whether the result is successful
    bool opCast(C : bool)()
    {
        return succeeded;
    }

    /// Returns: the error when unsuccessful, otherwise `fallback`
    E errorOr(E fallback)
    {
        return succeeded ? fallback : errStore;
    }

    /**
     * Returns: a pointer to the error, or `null` when successful
     *
     * The pointer refers into this `Result` and does not outlive it.
     */
    E* error()
    {
        return succeeded ? null : &errStore;
    }
}
