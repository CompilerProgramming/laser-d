# Implicit module: object

`object` makes the following string type aliases available without an explicit
import. It provides no structs or functions:

```d
module object;

alias string  = immutable(char)[];
alias wstring = immutable(wchar)[];
alias dstring = immutable(dchar)[];
```

These are immutable character slices, not allocating string objects.
The text-processing library is UTF-8-only; the presence of `wstring` and
`dstring` aliases does not provide UTF-16 or UTF-32 codecs.

## Using the library

No native archive is required.

## Implementation Details

Source: `library/object.d`.

The compiler implicitly imports this minimal module; it adds no runtime
initialization or allocating string implementation.
