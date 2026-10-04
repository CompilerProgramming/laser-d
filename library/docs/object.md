# Implicit module: object

Source: `library/object.d`. No native archive is required.

The compiler implicitly imports this minimal module. It provides only the
following type aliases, with no structs or functions:

```d
module object;

alias string  = immutable(char)[];
alias wstring = immutable(wchar)[];
alias dstring = immutable(dchar)[];
```

These are immutable character slices, not allocating string objects.
The text-processing library is UTF-8-only; the presence of `wstring` and
`dstring` aliases does not provide UTF-16 or UTF-32 codecs.
