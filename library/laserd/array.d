/**
 * Arena-backed dynamic array for Laser-D.
 *
 * The implementation began as a port of Phobos' `std.container.array` under
 * the Boost Software License 1.0, but its API and ownership model are specific
 * to Laser-D. All storage uses a mandatory, borrowed `laserd.memory.Arena*`.
 */
module laserd.array;

import core.stdc.stddef : size_t;
import core.stdc.string : memmove;
import laserd.memory : Arena;

/**
 * A growable array using a mandatory borrowed arena.
 *
 * Ordinary copies share state. The arena must outlive every copy and range.
 * Call `destroy` exactly once after the final copy and range is no longer used;
 * it releases storage through the arena but never destroys the arena itself.
 */
struct Array(T)
if (!is(immutable T == immutable bool))
{
    private struct State
    {
        Arena* arena;
        T[] storage;
        size_t used;
    }

    private State* state;

    struct Range
    {
        private State* state;
        private size_t first;
        private size_t pastLast;

        bool empty() { return first >= pastLast; }
        size_t length() { return pastLast - first; }
        alias opDollar = length;
        T front()
        {
            assert(!empty(), "front of an empty Array range");
            return state.storage[first];
        }
        T back()
        {
            assert(!empty(), "back of an empty Array range");
            return state.storage[pastLast - 1];
        }
        void popFront()
        {
            assert(!empty(), "popFront on an empty Array range");
            ++first;
        }
        void popBack()
        {
            assert(!empty(), "popBack on an empty Array range");
            --pastLast;
        }
        Range save() { return this; }
        T opIndex(size_t index)
        {
            assert(index < length(), "Array range index out of bounds");
            return state.storage[first + index];
        }
        void opIndexAssign(T value, size_t index)
        {
            assert(index < length(), "Array range index out of bounds");
            state.storage[first + index] = value;
        }
        Range opSlice() { return this; }
        Range opSlice(size_t begin, size_t end)
        {
            assert(begin <= end && end <= length(), "invalid Array range slice");
            Range result;
            result.state = state;
            result.first = first + begin;
            result.pastLast = first + end;
            return result;
        }
        void opSliceAssign(T value)
        {
            for (size_t i = first; i < pastLast; ++i)
                state.storage[i] = value;
        }
    }

    this(Arena* arena)
    {
        assert(arena !is null, "Array requires a non-null Arena*");
        state = arena.alloc!State();
        assert(state !is null, "Array state allocation failed");
        state.arena = arena;
    }

    this(Arena* arena, T[] values)
    {
        assert(arena !is null, "Array requires a non-null Arena*");
        state = arena.alloc!State();
        assert(state !is null, "Array state allocation failed");
        state.arena = arena;
        if (values.length != 0)
        {
            assert(reserve(values.length), "Array storage allocation failed");
            foreach (value; values)
                state.storage[state.used++] = value;
        }
    }

    bool initialized() { return state !is null; }
    bool empty() { return length() == 0; }
    size_t length() { return state is null ? 0 : state.used; }
    size_t opDollar() { return length(); }
    size_t capacity() { return state is null ? 0 : state.storage.length; }
    Arena* arena() { return state is null ? null : state.arena; }
    T[] data() { return state is null ? null : state.storage.ptr[0 .. state.used]; }

    bool reserve(size_t elements)
    {
        if (state is null)
            return false;
        if (elements <= capacity())
            return true;
        T[] expanded = state.arena.expandArray!T(state.storage, elements);
        if (expanded.ptr is null)
            return false;
        state.storage = expanded;
        return true;
    }

    bool resize(size_t newLength)
    {
        if (state is null)
            return false;
        if (newLength > capacity() && !reserve(newLength))
            return false;
        state.used = newLength;
        return true;
    }

    T opIndex(size_t index)
    {
        assert(index < length(), "Array index out of bounds");
        return state.storage[index];
    }
    void opIndexAssign(T value, size_t index)
    {
        assert(index < length(), "Array index out of bounds");
        state.storage[index] = value;
    }
    T front()
    {
        assert(!empty(), "front of an empty Array");
        return state.storage[0];
    }
    T back()
    {
        assert(!empty(), "back of an empty Array");
        return state.storage[state.used - 1];
    }
    Range opSlice() { return makeRange(0, length()); }
    Range opSlice(size_t begin, size_t end)
    {
        assert(begin <= end && end <= length(), "invalid Array slice");
        return makeRange(begin, end);
    }
    private Range makeRange(size_t begin, size_t end)
    {
        Range result;
        result.state = state;
        result.first = begin;
        result.pastLast = end;
        return result;
    }
    void opSliceAssign(T value)
    {
        for (size_t i = 0; i < length(); ++i)
            state.storage[i] = value;
    }
    void opSliceAssign(T value, size_t begin, size_t end)
    {
        assert(begin <= end && end <= length(), "invalid Array slice assignment");
        for (size_t i = begin; i < end; ++i)
            state.storage[i] = value;
    }

    size_t insertBack(T value)
    {
        if (!ensureAdditional(1))
            return 0;
        state.storage[state.used++] = value;
        return 1;
    }
    size_t insertBack(T[] values)
    {
        if (values.length == 0)
            return 0;

        size_t valueCount = values.length;
        size_t sourceOffset = size_t.max;
        for (size_t i = 0; i < length(); ++i)
            if (values.ptr is state.storage.ptr + i)
                sourceOffset = i;

        if (!ensureAdditional(valueCount))
            return 0;
        if (sourceOffset != size_t.max)
            values = state.storage.ptr[sourceOffset .. sourceOffset + valueCount];
        foreach (value; values)
            state.storage[state.used++] = value;
        return valueCount;
    }
    alias insert = insertBack;
    void opOpAssign(string operation)(T value) if (operation == "~") { insertBack(value); }
    void opOpAssign(string operation)(T[] values) if (operation == "~") { insertBack(values); }

    size_t insertBefore(Range range, T value)
    {
        assert(validRange(range), "range does not belong to this Array");
        size_t offset = range.first;
        if (!ensureAdditional(1))
            return 0;
        memmove(state.storage.ptr + offset + 1, state.storage.ptr + offset,
                (state.used - offset) * T.sizeof);
        state.storage[offset] = value;
        ++state.used;
        return 1;
    }
    alias stableInsertBefore = insertBefore;
    size_t insertAfter(Range range, T value)
    {
        assert(validRange(range), "range does not belong to this Array");
        return insertBefore(makeRange(range.pastLast, range.pastLast), value);
    }

    T removeAny()
    {
        T result = back();
        removeBack();
        return result;
    }
    alias stableRemoveAny = removeAny;
    void removeBack()
    {
        assert(!empty(), "removeBack on an empty Array");
        --state.used;
        state.storage[state.used] = T.init;
    }
    alias stableRemoveBack = removeBack;
    size_t removeBack(size_t howMany)
    {
        if (howMany > length())
            howMany = length();
        size_t oldLength = length();
        size_t newLength = oldLength - howMany;
        for (size_t i = newLength; i < oldLength; ++i)
            state.storage[i] = T.init;
        state.used = newLength;
        return howMany;
    }
    Range linearRemove(Range range)
    {
        assert(validRange(range), "range does not belong to this Array");
        size_t removed = range.pastLast - range.first;
        size_t tail = state.used - range.pastLast;
        memmove(state.storage.ptr + range.first, state.storage.ptr + range.pastLast,
                tail * T.sizeof);
        state.used -= removed;
        for (size_t i = state.used; i < state.used + removed; ++i)
            state.storage[i] = T.init;
        return makeRange(range.first, state.used);
    }
    alias stableLinearRemove = linearRemove;
    size_t replace(Range range, T value)
    {
        assert(validRange(range), "range does not belong to this Array");
        if (range.empty())
            return insertBefore(range, value);
        state.storage[range.first] = value;
        if (range.length() > 1)
            linearRemove(makeRange(range.first + 1, range.pastLast));
        return 1;
    }

    Array dup()
    {
        Array result = Array(state.arena);
        if (length() != 0)
        {
            assert(result.reserve(length()), "Array duplication failed");
            foreach (value; data())
                result.state.storage[result.state.used++] = value;
        }
        return result;
    }
    bool opEquals(ref Array rhs)
    {
        if (length() != rhs.length())
            return false;
        for (size_t i = 0; i < length(); ++i)
            if (state.storage[i] != rhs.state.storage[i])
                return false;
        return true;
    }
    void clear()
    {
        if (state is null)
            return;
        state.arena.freeArray!T(state.storage);
        state.storage = null;
        state.used = 0;
    }

    /** Releases the payload and shared state, invalidating all copies/ranges. */
    void destroy()
    {
        if (state is null)
            return;
        State* oldState = state;
        clear();
        oldState.arena.free(oldState);
        state = null;
    }

    private bool validRange(Range range)
    {
        return range.state is state && range.first <= range.pastLast
            && range.pastLast <= length();
    }
    private bool ensureAdditional(size_t count)
    {
        if (state is null || count > size_t.max - length())
            return false;
        size_t required = length() + count;
        if (required <= capacity())
            return true;
        size_t grown = capacity() + capacity() / 2 + 1;
        if (grown < capacity() || grown < required)
            grown = required;
        return reserve(grown);
    }
}
