// A Laser-D-compatible subset of Phobos' std.traits.
//
// This module is derived from std/traits.d in Phobos under the Boost
// Software License 1.0.  The declarations below retain their upstream names
// and meanings where Laser-D has the language support needed to implement
// and test them.
module std.traits;

alias ConstOf(T) = const(T);
alias ImmutableOf(T) = immutable(T);

template ReturnType(alias functionSymbol)
{
    static if (is(typeof(functionSymbol) Result == return))
        alias ReturnType = Result;
    else
        static assert(0, "argument has no return type");
}

template Parameters(alias functionSymbol)
{
    static if (is(typeof(functionSymbol) Params == function))
        alias Parameters = Params;
    else
        static assert(0, "argument has no parameters");
}

alias ParameterTypeTuple = Parameters;

enum arity(alias functionSymbol) = Parameters!functionSymbol.length;

template Fields(T)
{
    alias Fields = typeof(T.tupleof);
}

alias FieldTypeTuple = Fields;

enum hasMember(T, immutable(char)[] name) = __traits(hasMember, T, name);
enum hasElaborateDestructor(T) = __traits(needsDestruction, T);

enum bool isBoolean(T) = is(T == bool);
enum bool isIntegral(T) = __traits(isIntegral, T);
enum bool isFloatingPoint(T) = __traits(isFloating, T);
enum bool isNumeric(T) = __traits(isArithmetic, T);
enum bool isScalarType(T) = __traits(isScalar, T);
enum bool isBasicType(T) = isScalarType!T || is(T == void);
enum bool isUnsigned(T) = __traits(isUnsigned, T) && isIntegral!T;
enum bool isSigned(T) = isIntegral!T && !isUnsigned!T;
enum bool isSomeChar(T) =
    is(T == char) || is(T == wchar) || is(T == dchar);
enum bool isSomeString(T) =
    is(immutable T == immutable C[], C) && isSomeChar!C;
enum bool isNarrowString(T) =
    is(immutable T == immutable C[], C) &&
    (is(C == char) || is(C == wchar));
enum bool isStaticArray(T) = __traits(isStaticArray, T);
enum bool isDynamicArray(T) = is(T == E[], E);
enum bool isArray(T) = isStaticArray!T || isDynamicArray!T;
enum bool isAssociativeArray(T) = __traits(isAssociativeArray, T);
enum bool isPointer(T) = is(T == P*, P);
alias PointerTarget(T : T*) = T;
enum bool isAggregateType(T) =
    is(T == struct) || is(T == union) ||
    is(T == class) || is(T == interface);
enum bool isBuiltinType(T) = isBasicType!T || isArray!T ||
    isAssociativeArray!T || isPointer!T;
enum bool isMutable(T) =
    !is(T == const) && !is(T == immutable);
enum bool isImplicitlyConvertible(From, To) = is(From : To);
enum bool isInstanceOf(alias Template, T) = is(T == Template!Args, Args...);
enum bool isFunctionPointer(alias symbol) =
    is(typeof(*symbol) == function);
enum bool isDelegate(alias symbol) =
    is(typeof(symbol) == delegate) || is(symbol == delegate);
enum bool isSomeFunction(alias symbol) =
    is(typeof(symbol) == function) || isFunctionPointer!symbol ||
    isDelegate!symbol;

alias KeyType(V : V[K], K) = K;
alias ValueType(V : V[K], K) = V;

template Select(bool condition, T, F)
{
    static if (condition)
        alias Select = T;
    else
        alias Select = F;
}

enum mangledName(alias symbol) = symbol.mangleof;

/*
Deferred upstream groups (kept here as a review inventory):

- shared/inout qualifier constructors: Laser-D rejects shared and inout.
- class/interface and nested-symbol inspection: native D classes and hidden
  contexts are outside the language subset.
- elaborate copy/move/assignment analysis: postblits, destructors, and copy
  constructors are rejected.
- associative-array helpers: built-in associative arrays are rejected.
- SIMD, complex, imaginary, cent and real helpers: those types are rejected.
- UDA helpers: user-defined attributes are rejected.
- callable adaptation, function-attribute rewriting, common-type inference,
  enum iteration, and recursive representation analysis: not yet extracted
  and therefore not part of the supported library surface.
*/
