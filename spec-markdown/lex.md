---
title: Lexical analysis
status: supported
source: ../spec/lex.dd
---

# Lexical

The lexical analysis is independent of the syntax parsing and the semantic
analysis. The lexical analyzer splits the source text into tokens. The
lexical grammar describes the syntax of these tokens. The grammar is designed to
be suitable for high-speed scanning and to facilitate the implementation of a correct
scanner. It has a minimum of special case rules and there is only one
phase of translation.

## <a id="source_text"></a>Source Text

> **Laser-D normative:**
>
> Laser-D retains D lexical analysis unchanged. Source text, whitespace, comments, identifiers, tokens, literals, escape sequences, keywords, and
> special tokens described in this chapter are part of Laser-D. A construct may
> be lexically valid but still be rejected by a later Laser-D grammar or semantic
> restriction.

Lexical recognition does not imply language support. In particular, the
lexer continues to recognize every D keyword and the `L` and `i`
floating-point suffixes so that the frontend can issue precise diagnostics.
Laser-D source may not use a recognized token to construct a feature rejected
by another normative chapter.

```text
SourceFile:
    ByteOrderMark Module[]
    Shebang Module[]
    Module[]
```

```text
ByteOrderMark:
    \uFEFF

Shebang:
    #! Characters[] EndOfShebang

EndOfShebang:
    \u000A
    EndOfFile
```

Source text can be encoded as any one of the following:

- ASCII (strictly, 7-bit ASCII)
- UTF-8
- UTF-16BE
- UTF-16LE
- UTF-32BE
- UTF-32LE

One of the following UTF
BOMs (Byte Order Marks) can be present at the beginning of the source text:

| Format | BOM |
| --- | --- |
| UTF-8 | EF BB BF |
| UTF-16BE | FE FF |
| UTF-16LE | FF FE |
| UTF-32BE | 00 00 FE FF |
| UTF-32LE | FF FE 00 00 |
| ASCII | no BOM |

If the source file does not begin with a BOM, then the first character must
be less than or equal to U+0000007F.

The source text is decoded from its source representation into Unicode
Characters. The Characters are further divided into: WhiteSpace, EndOfLine, Comments, SpecialTokenSequences, and Tokens, with the source terminated by an EndOfFile.

The source text is split into tokens using the maximal munch algorithm, i.e., the lexical analyzer assumes the longest possible token. For example, `>>` is a right-shift token rather than two greater-than tokens. There are two
exceptions to this rule:

- A `..` embedded between what appear to be two floating point literals, as in `1..2`, is interpreted as if the `..` were separated by a space from the first integer.
- A `1.a` is interpreted as the three tokens `1`, `.`, and `a`, whereas `1. a` is interpreted as the two tokens `1.` and `a`.

## <a id="character_set"></a>Character Set

```text
Character:
    *any Unicode character*
```

## <a id="end_of_file"></a>End of File

```text
EndOfFile:
    *physical end of the file*
    \u0000
    \u001A
```

The source text is terminated by whichever comes first.

## <a id="end_of_line"></a>End of Line

```text
EndOfLine:
    \u000D
    \u000A
    \u000D \u000A
    \u2028
    \u2029
    EndOfFile
```

## <a id="white_space"></a>White Space

```text
WhiteSpace:
    Space
    Space WhiteSpace

Space:
    \u0020
    \u0009
    \u000B
    \u000C
```

## <a id="comment"></a>Comments

```text
Comment:
    BlockComment
    LineComment
    NestingBlockComment

BlockComment:
    /* Characters[] */

LineComment:
    // Characters[] EndOfLine

NestingBlockComment:
    /+ NestingBlockCommentCharacters[] +/

NestingBlockCommentCharacters:
    NestingBlockCommentCharacter
    NestingBlockCommentCharacter NestingBlockCommentCharacters

NestingBlockCommentCharacter:
    Character
    NestingBlockComment

Characters:
    Character
    Character Characters
```

There are three kinds of comments:

1. Block comments can span multiple lines, but do not nest.
2. Line comments terminate at the end of the line.
3. Nesting block comments can span multiple lines and can nest.

The contents of strings and comments are not tokenized.  Consequently, comment openings occurring within a string do not begin a comment, and
        string delimiters within a comment do not affect the recognition of
        comment closings and nested `/+` comment openings.  With the exception
        of `/+` occurring within a `/+` comment, comment openings within a
        comment are ignored.

```d
a = /+ // +/ 1;    // parses as if 'a = 1;'
a = /+ "+/" +/ 1"; // parses as if 'a = " +/ 1";'
a = /+ /* +/ */ 3; // parses as if 'a = */ 3;'
```

Comments cannot be used as token concatenators, for example, `abc/**/def`
is two tokens, `abc` and `def`, not one `abcdef` token.

## <a id="tokens"></a>Tokens

```text
Tokens:
    Token
    Token Tokens

Token:
    {
    }
    TokenNoBraces

TokenNoBraces:

- Identifier StringLiteral InterpolationExpressionSequence CharacterLiteral IntegerLiteral FloatLiteral Keyword / /= . .. ... & &= && | |= || - -= -- + += ++ < <= << <<= > >= >>= >>>= >> >>> ! != ( ) [ ] ? , ; : $ = == * *= % %= ^ ^= ^^ ^^= ~ ~= @ =>
```

## <a id="identifiers"></a>Identifiers

```text
Identifier:
    IdentifierStart
    IdentifierStart IdentifierChars

IdentifierChars:
    IdentifierChar
    IdentifierChar IdentifierChars

IdentifierStart:
    _
    *Letter*
    *UniversalAlpha*

IdentifierChar:
    IdentifierStart
    0
    NonZeroDigit
```

Identifiers start with a letter, `_`, or universal alpha, and are
followed by any number of letters, `_`, digits, or universal alphas.
Universal alphas are as defined in ISO/IEC 9899:1999(E) Appendix D of the C99 Standard.
Identifiers can be arbitrarily long, and are case sensitive.

> **Implementation-defined:** Identifiers starting with `__` (two underscores) are reserved.

## <a id="string_literals"></a>String Literals

> **Laser-D normative:**
>
> String literals are supported as immutable character slices over
> compiler-owned static storage and do not allocate GC-owned memory.

```text
StringLiteral:
    WysiwygString
    AlternateWysiwygString
    DoubleQuotedString
    DelimitedString
    TokenString
    HexString
```

A string literal is either a wysiwyg quoted string, a double quoted
string, a delimited string, a token string, or a hex string.

In all string literal forms, an EndOfLine is regarded as a single
`\n` character.

### <a id="wysiwyg"></a>Wysiwyg Strings

```text
WysiwygString:
    r" WysiwygCharacters[] " StringPostfix[]

AlternateWysiwygString:
     WysiwygCharacters[]  StringPostfix[]

WysiwygCharacters:
    WysiwygCharacter
    WysiwygCharacter WysiwygCharacters

WysiwygCharacter:
    Character
    EndOfLine
```

Wysiwyg ("what you see is what you get") quoted strings can be defined
        using either of two syntaxes.

In the first form, they are enclosed between `r"` and `"`.
        All characters between
        the `r"` and `"` are part of the string.
        There are no escape sequences inside wysiwyg strings.

```d
r"I am Oz"
        r"c:\games\Sudoku.exe"
        r"ab\n" // string is 4 characters
// 'a'
'b'
'\'
'n'
```

Alternatively, wysiwyg strings can be enclosed by backquotes, using the ` character.

```d
the Great and Powerful.
        c:\games\Empire.exe
        The "lazy" dog
        a"b\n  // string is 5 characters
// 'a'
'"'
'b'
'\'
'n'
```

See also InterpolatedWysiwygLiteral

### <a id="double_quoted_strings"></a>Double Quoted Strings

```text
DoubleQuotedString:
    " DoubleQuotedCharacters[] " StringPostfix[]

DoubleQuotedCharacters:
    DoubleQuotedCharacter
    DoubleQuotedCharacter DoubleQuotedCharacters

DoubleQuotedCharacter:
    Character
    EscapeSequence
    EndOfLine
```

Double quoted strings are enclosed by "". EscapeSequences can be
        embedded in them.

```d
"Who are you?"
        "c:\\games\\Doom.exe"
        "ab\n"   // string is 3 characters
// 'a'
'b'
and a linefeed
        "ab
        "        // string is 3 characters
// 'a'
'b'
and a linefeed
```

See also InterpolatedDoubleQuotedLiteral

### <a id="delimited_strings"></a>Delimited Strings

```text
DelimitedString:
    q" Delimiter WysiwygCharacters[] MatchingDelimiter " StringPostfix[]
    q"( ParenDelimitedCharacters[] )" StringPostfix[]
    q"[ BracketDelimitedCharacters[] ]" StringPostfix[]
    q"{ BraceDelimitedCharacters[] }" StringPostfix[]
    q"< AngleDelimitedCharacters[] >" StringPostfix[]

Delimiter:
    Identifier

MatchingDelimiter:
    Identifier

ParenDelimitedCharacters:
    WysiwygCharacter
    WysiwygCharacter ParenDelimitedCharacters
    ( ParenDelimitedCharacters[] )

BracketDelimitedCharacters:
    WysiwygCharacter
    WysiwygCharacter BracketDelimitedCharacters
    [ BracketDelimitedCharacters[] ]

BraceDelimitedCharacters:
    WysiwygCharacter
    WysiwygCharacter BraceDelimitedCharacters
    { BraceDelimitedCharacters[] }

AngleDelimitedCharacters:
    WysiwygCharacter
    WysiwygCharacter AngleDelimitedCharacters
    < AngleDelimitedCharacters[] >
```

Delimited strings use various forms of delimiters.
        The delimiter, whether a character or identifier, must immediately follow the " without any intervening whitespace.
        The terminating delimiter must immediately precede the closing "
        without any intervening whitespace.
        A *nesting delimiter* nests, and is one of the
        following characters:

| Delimiter | Matching Delimiter |
| --- | --- |
| `[` | `]` |
| ( | ) |
| `<` | `>` |
| { | } |

```d
q"(foo(xxx))"   // "foo(xxx)"
q"[foo{]"       // "foo{"
```

If the delimiter is an identifier, the identifier must
        be immediately followed by a newline, and the matching
        delimiter must be the same identifier starting at the beginning
        of the line:

```d
writeln(q"EOS
This
is a multi-line
heredoc string
EOS"
);
```

The newline following the opening identifier is not part
        of the string, but the last newline before the closing
        identifier is part of the string. The closing identifier
    must be placed on its own line at the leftmost column.

Otherwise, the matching delimiter is the same as
        the delimiter character:

```d
q"/foo]/"          // "foo]"
// q"/abc/def/"    // error
```

### <a id="token_strings"></a>Token Strings

```text
TokenString:
    q{ TokenStringTokens[] } StringPostfix[]

TokenStringTokens:
    TokenStringToken
    TokenStringToken TokenStringTokens

TokenStringToken:
    TokenNoBraces
    { TokenStringTokens[] }
```

Token strings open with the characters `q`{ and close with
        the token }. In between must be valid D tokens.
        The { and } tokens nest.
        The string is formed of all the characters between the opening
        and closing of the token string, including comments.

```d
q{this is the voice of} // "this is the voice of"
        q{/*}*/ }               // "/*}*/ "
        q{ world(q{control}); } // " world(q{control}); "
        q{ __TIME__ }           // " __TIME__ "
                                // i.e. it is not replaced with the time
        // q{ __EOF__ }         // error
                                // __EOF__ is not a token
it's end of file
```

See also InterpolatedTokenLiteral

### <a id="hex_strings"></a>Hex Strings

```text
HexString:
    x" HexStringChars[] " StringPostfix[]

HexStringChars:
    HexStringChar
    HexStringChar HexStringChars

HexStringChar:
    HexDigit
    WhiteSpace
    EndOfLine
```

Hex strings allow string literals to be created using hex data.
        The hex data need not form valid UTF characters.

```d
x"0A"              // same as "\x0A"
        x"00 FBCD 32FD 0A" // same as "\x00\xFB\xCD\x32\xFD\x0A"
```

Whitespace and newlines are ignored, so the hex data can be easily
        formatted. The number of hex characters must be a multiple of 2.

### <a id="string_postfix"></a>String Postfix

```text
StringPostfix:
    c
    w
    d
```

The optional *StringPostfix* character gives a specific type
        to the string, rather than it being inferred from the context.
        The types corresponding to the postfix characters are:

| Postfix | Type | Alias |
| --- | --- | --- |
| **c** | `immutable(char)[]` | `string` |
| **w** | `immutable(wchar)[]` | `wstring` |
| **d** | `immutable(dchar)[]` | `dstring` |

```d
"hello"c  // string
"hello"w  // wstring
"hello"d  // dstring
```

The string literals are assembled as UTF-8 char arrays, and the postfix is applied
        to convert to wchar or dchar as necessary as a final step.

## <a id="escape_sequences"></a>Escape Sequences

```text
EscapeSequence:
    \\'
    \\"
    \\?
    \\\\
    \0
    \a
    \b
    \f
    \n
    \r
    \t
    \v
    \x HexDigit HexDigit
    \\ OctalDigit
    \\ OctalDigit OctalDigit
    \\ OctalDigit OctalDigit OctalDigit
    \u HexDigit HexDigit HexDigit HexDigit
    \U HexDigit HexDigit HexDigit HexDigit HexDigit HexDigit HexDigit HexDigit
    \\ NamedCharacterEntity

OctalDigit:
    0
    1
    2
    3
    4
    5
    6
    7
```

| Sequence | Meaning |
| --- | --- |
| `\'` | Literal single-quote: `'` |
| `\"` | Literal double-quote: `"` |
| `\?` | Literal question mark: `?` |
| `\\` | Literal backslash: `\` |
| `\0` | Binary zero (NUL, U+0000). |
| `\a` | BEL (alarm) character (U+0007). |
| `\b` | Backspace (U+0008). |
| `\f` | Form feed (FF) (U+000C). |
| `\n` | End-of-line (U+000A). |
| `\r` | Carriage return (U+000D). |
| `\t` | Horizontal tab (U+0009). |
| `\v` | Vertical tab (U+000B). |
| `\x`*nn* | Byte value in hexadecimal, where *nn* is specified as two hexadecimal digits. For example: `\xFF` represents the character with the value 255.  See also: conv. |
| `\`*n* `\`*nn* `\`*nnn* | Byte value in octal. For example: `\101` represents the character with the value 65 (`'A'`). Analogous to hexadecimal characters, the largest byte value is `\377` (= `\xFF` in hexadecimal or `255` in decimal)  See also: conv. |
| `\u`*nnnn* | Unicode character U+*nnnn*, where *nnnn* are four hexadecimal digits. For example, `\u03B3` represents the Unicode character γ (U+03B3 - GREEK SMALL LETTER GAMMA). |
| `\U`*nnnnnnnn* | Unicode character U+*nnnnnnnn*, where *nnnnnnnn* are 8 hexadecimal digits. For example, `\U0001F603` represents the Unicode character U+1F603 (SMILING FACE WITH OPEN MOUTH). |
| `\`*name* | Named character entity from the HTML5 specification. These names begin with & and end with `;`, e.g., `€`. See NamedCharacterEntity. |

## <a id="characterliteral"></a>Character Literals

```text
CharacterLiteral:
    ' SingleQuotedCharacter '

SingleQuotedCharacter:
    Character
    EscapeSequence
```

Character literals are a single character or escape sequence enclosed by
single quotes.

```d
'h'   // the letter h
    '\n'  // newline
    '\\'  // the backslash character
```

A character literal resolves to one
    of type `char`, `wchar`, or `dchar`
    (see [Basic Data Types](type.md#basic-data-types)).

- If the literal is a `\u` escape sequence, it resolves to type `wchar`.
- If the literal is a `\U` escape sequence, it resolves to type `dchar`.

Otherwise, it resolves to the type with the smallest size it
    will fit into.

## <a id="integerliteral"></a>Integer Literals

```text
IntegerLiteral:
    Integer
    Integer IntegerSuffix

Integer:
    DecimalInteger
    BinaryInteger
    HexadecimalInteger

IntegerSuffix:
    L
    u
    U
    Lu
    LU
    uL
    UL
```

```text
DecimalInteger:
    0 Underscores[]
    NonZeroDigit
    NonZeroDigit DecimalDigitsUS

Underscores:
    _
    Underscores _

NonZeroDigit:
    1
    2
    3
    4
    5
    6
    7
    8
    9

DecimalDigits:
    DecimalDigit
    DecimalDigit DecimalDigits

DecimalDigitsUS:
    DecimalDigitUS
    DecimalDigitUS DecimalDigitsUS

DecimalDigitsNoSingleUS:
    DecimalDigitsUS[] DecimalDigit DecimalDigitsUS[]

DecimalDigitsNoStartingUS:
    DecimalDigit
    DecimalDigit DecimalDigitsUS

DecimalDigit:
    0
    NonZeroDigit

DecimalDigitUS:
    DecimalDigit
    _
```

```text
BinaryInteger:
    BinPrefix BinaryDigitsNoSingleUS

BinPrefix:
    0b
    0B

BinaryDigitsNoSingleUS:
    BinaryDigitsUS[] BinaryDigit BinaryDigitsUS[]

BinaryDigitsUS:
    BinaryDigitUS
    BinaryDigitUS BinaryDigitsUS

BinaryDigit:
    0
    1

BinaryDigitUS:
    BinaryDigit
    _
```

```text
HexadecimalInteger:
    HexPrefix HexDigitsNoSingleUS

HexDigits:
    HexDigit
    HexDigit HexDigits

HexDigitsUS:
    HexDigitUS
    HexDigitUS HexDigitsUS

HexDigitsNoSingleUS:
    HexDigitsUS[] HexDigit HexDigitsUS[]

HexDigitsNoStartingUS:
    HexDigit
    HexDigit HexDigitsUS

HexDigit:
    DecimalDigit
    HexLetter

HexDigitUS:
    HexDigit
    _

HexLetter:
    a
    b
    c
    d
    e
    f
    A
    B
    C
    D
    E
    F
```

Integers can be specified in decimal, binary, or hexadecimal.

- Decimal integers are a sequence of decimal digits.
- <a id="binary-literals"></a>Binary integers are a sequence of binary digits preceded by a ' or '.
- C-style octal integer notation (e.g. `0167`) was deemed too easy to mix up with decimal notation; it is only fully supported in string literals. D still supports octal integer literals interpreted at compile time through the conv template, as in `octal!167`.
- Hexadecimal integers are a sequence of hexadecimal digits preceded by a ' or '.

```d
10      // decimal
0b1010  // binary
0xA     // hex
```

Integers can have embedded ' characters after a digit to improve readability, which are ignored.

```d
20_000        // leagues under the sea
        867_5309      // number on the wall
        1_522_000     // thrust of F1 engine (lbf sea level)
        0xBAAD_F00D   // magic number for debugging
```

Integers can be immediately followed by one ' or one of
        ' or ' or both.
        Note that there is no ' suffix.

The type of the integer is resolved as follows:

| Literal | Type |
| --- | --- |
| *Usual decimal notation* |  |
| `0 .. 2_147_483_647` | `int` |
| `2_147_483_648 .. 9_223_372_036_854_775_807` | `long` |
| `9_223_372_036_854_775_808 .. 18_446_744_073_709_551_615` | `ulong` |
| *Explicit suffixes* |  |
| `0L .. 9_223_372_036_854_775_807L` | `long` |
| `0U .. 4_294_967_295U` | `uint` |
| `4_294_967_296U .. 18_446_744_073_709_551_615U` | `ulong` |
| `0UL .. 18_446_744_073_709_551_615UL` | `ulong` |
| *Hexadecimal notation* |  |
| `0x0 .. 0x7FFF_FFFF` | `int` |
| `0x8000_0000 .. 0xFFFF_FFFF` | `uint` |
| `0x1_0000_0000 .. 0x7FFF_FFFF_FFFF_FFFF` | `long` |
| `0x8000_0000_0000_0000 .. 0xFFFF_FFFF_FFFF_FFFF` | `ulong` |
| *Hexadecimal notation with explicit suffixes* |  |
| `0x0L .. 0x7FFF_FFFF_FFFF_FFFFL` | `long` |
| `0x8000_0000_0000_0000L .. 0xFFFF_FFFF_FFFF_FFFFL` | `ulong` |
| `0x0U .. 0xFFFF_FFFFU` | `uint` |
| `0x1_0000_0000U .. 0xFFFF_FFFF_FFFF_FFFFU` | `ulong` |
| `0x0UL .. 0xFFFF_FFFF_FFFF_FFFFUL` | `ulong` |

An integer literal may not exceed these values.

> **Best practice:**
>
> Octal integer notation is not supported for integer literals.
>         However, octal integer literals can be interpreted at compile time through
>         the conv template, as in `octal!167`.

## <a id="floatliteral"></a>Floating Point Literals

> **Laser-D normative:**
>
> Laser-D floating-point literals have type `double` when
> unsuffixed and type `float` when followed by `f` or `F`. The lexer
> recognizes the D suffixes `L` and `i`, but a Laser-D source file using
> either suffix is rejected. The rejected suffixes remain recognized for clear
> diagnostics and for the ImportC frontend.

```text
FloatLiteral:
    Float Suffix[]
    Integer FloatSuffix ImaginarySuffix[]
    Integer RealSuffix[] ImaginarySuffix

Float:
    DecimalFloat
    HexFloat

DecimalFloat:
    LeadingDecimal . DecimalDigitsNoStartingUS[]
    LeadingDecimal . DecimalDigitsNoStartingUS DecimalExponent
    . DecimalDigitsNoStartingUS DecimalExponent[]
    LeadingDecimal DecimalExponent

DecimalExponent:
    DecimalExponentStart DecimalDigitsNoSingleUS

DecimalExponentStart:
    e
    E
    e+
    E+
    e-
    E-

HexFloat:
    HexPrefix HexDigitsNoSingleUS . HexDigitsNoStartingUS HexExponent
    HexPrefix . HexDigitsNoStartingUS HexExponent
    HexPrefix HexDigitsNoSingleUS HexExponent
    HexPrefix HexExponent

HexPrefix:
    0x
    0X

HexExponent:
    HexExponentStart DecimalDigitsNoSingleUS

HexExponentStart:
    p
    P
    p+
    P+
    p-
    P-

Suffix:
    FloatSuffix ImaginarySuffix[]
    RealSuffix ImaginarySuffix[]
    ImaginarySuffix

FloatSuffix:
    f
    F

RealSuffix:
    L

ImaginarySuffix:
    i

LeadingDecimal:
    DecimalInteger
    0 DecimalDigitsNoSingleUS
```

Floats can be in decimal or hexadecimal format, and must have
        at least one digit and either a decimal point, an exponent, or
        a *FloatSuffix*.

Decimal floats can have an exponent which is `e` or `E` followed
        by a decimal number serving as the exponent of 10.

```d
-1.0
1e2               // 100.0
1e-2              // 0.01
-1.175494351e-38F // float.min
```

Hexadecimal floats are preceded by a **0x** or **0X** and the
        exponent is a **p** or **P** followed by a decimal number serving as
        the exponent of 2.

```d
0xAp0                  // 10.0
0x1p2                  // 4.0
0x1.FFFFFFFFFFFFFp1023 // double.max
0x1p-52                // double.epsilon
```

Floating literals can have embedded `_` characters
        after a digit to improve readability, which are ignored.

```d
2.645_751
        6.022140857E+23
        6_022.140857E+20
        6_022_.140_857E+20_
```

- Floating literals with no suffix are of type `double`.
- Floating literals followed by **f** or **F** are of type `float`.
- Floating literals followed by **L**, or by the imaginary suffix **i**, are not valid Laser-D expressions.

```d
0.0                    // double
0F                     // float
0.0L                   // lexed
then rejected by Laser-D
```

The literal may not exceed the range of the type.
        The literal is rounded to fit into
        the significant digits of the type.

If a floating literal has a `.` and a type suffix, at least one
            digit must be in-between:

```d
1f;  // OK
float
        1.f; // error
        1.;  // OK
double
```

> **Excluded from Laser-D:**
>
> The **L** suffix denotes D's unsupported `real`
>         type, and the **i** suffix denotes an unsupported imaginary type.
>         Neither suffix is available to Laser-D programs.

## <a id="keywords"></a>Keywords

All D keywords remain reserved identifiers. Reservation prevents a
        token from being used as an identifier; it does not mean that the D
        construct introduced by that keyword is part of Laser-D.

> **Laser-D normative:**
>
> The keyword table below is a lexical table. Keywords
>         associated with excluded features remain reserved and are rejected by
>         the applicable grammar or semantic rule. ImportC applies the C lexical
>         and language rules described in the ImportC chapter.

```text
Keyword:

- attribute.html#abstract, abstract
- declaration.html#alias, alias
- attribute.html#align, align
- statement.html#AsmStatement, asm
- expression.html#AssertExpression, assert
- attribute.html#auto, auto
- function.html#BodyStatement, body
- type.html, bool
- statement.html#BreakStatement, break
- type.html, byte
- statement.html#SwitchStatement, case
- expression.html#CastExpression, cast
- statement.html#TryStatement, catch
- type.html, cdouble
- type.html, cent
- type.html, cfloat
- type.html, char
- class.html, class
- attribute.html#const, const
- statement.html#ContinueStatement, continue
- type.html, creal
- type.html, dchar
- version.html#debug, debug
- statement.html#SwitchStatement, default
- type.html#delegates, delegate
- expression.html#DeleteExpression, delete
- attribute.html#deprecated, deprecated
- statement.html#DoStatement, do
- type.html, double
- statement.html#IfStatement, else
- enum.html, enum
- attribute.html#visibility_attributes, export
- attribute.html#linkage, extern
- type.html, false
- class.html#final, final
- statement.html#TryStatement, finally
- type.html, float
- statement.html#ForStatement, for
- statement.html#ForeachStatement, foreach
- statement.html#ForeachStatement, foreach_reverse
- expression.html#FunctionLiteral, function
- statement.html#GotoStatement, goto
- type.html, idouble
- statement.html#IfStatement, if
- type.html, ifloat
- attribute.html#immutable, immutable
- expression.html#ImportExpression, import
- expression.html#InExpression, in
- function.html#inout-functions, inout
- type.html, int
- interface.html, interface
- contracts.html, invariant
- type.html, ireal
- expression.html#IsExpression, is
- function.html#overload-sets, lazy
- type.html, long
- expression.html#MixinExpression, mixin
- module.html#ModuleDeclaration, module
- expression.html#NewExpression, new
- function.html#nothrow-functions, nothrow
- expression.html#null, null
- function.html#OutStatement, out
- attribute.html#override, override
- attribute.html#visibility_attributes, package
- pragma.html, pragma
- attribute.html#visibility_attributes, private
- attribute.html#visibility_attributes, protected
- attribute.html#visibility_attributes, public
- function.html#pure-functions, pure
- type.html, real
- function.html#ref-functions, ref
- statement.html#ReturnStatement, return
- statement.html#ScopeGuardStatement, scope
- attribute.html#shared, shared
- type.html, short
- version.html#staticif, static
- struct.html, struct
- expression.html#super, super
- statement.html#SwitchStatement, switch
- statement.html#SynchronizedStatement, synchronized
- template.html, template
- expression.html#this, this
- statement.html#ThrowStatement, throw
- type.html, true
- statement.html#TryStatement, try
- expression.html#TypeidExpression, typeid
- type.html#Typeof, typeof
- type.html, ubyte
- type.html, ucent
- type.html, uint
- type.html, ulong
- struct.html, union
- unittest.html, unittest
- type.html, ushort
- version.html#version, version
- declaration.html#VoidInitializer, void
- type.html, wchar
- statement.html#WhileStatement, while
- statement.html#WithStatement, with
- expression.html#specialkeywords, __FILE__
- expression.html#specialkeywords, __FILE_FULL_PATH__
- expression.html#specialkeywords, __FUNCTION__
- expression.html#specialkeywords, __LINE__
- expression.html#specialkeywords, __MODULE__
- expression.html#specialkeywords, __PRETTY_FUNCTION__
- attribute.html#gshared, __gshared
- expression.html#IsExpression, __parameters
- expression.html#RvalueExpression, __rvalue
- traits.html, __traits
- ../phobos/core_simd.html#.Vector, __vector
```

## <a id="specialtokens"></a>Special Tokens

These tokens are replaced with other tokens according to the following
        table:

| Special Token | Replaced with |
| --- | --- |
| `__DATE__` | string literal of the date of compilation "*mmm dd yyyy*" |
| `__EOF__` | tells the scanner to ignore everything after this token |
| `__TIME__` | string literal of the time of compilation "*hh:mm:ss*" |
| `__TIMESTAMP__` | string literal of the date and time of compilation "*www mmm dd hh:mm:ss yyyy*" |
| `__VENDOR__` | Compiler vendor string |
| `__VERSION__` | Compiler version as an integer |

> **Implementation-defined:** The replacement string literal for `__VENDOR__` and the replacement integer value for `__VERSION__`.

## <a id="Special Token Sequence"></a>Special Token Sequences

```text
SpecialTokenSequence:
    # line IntegerLiteral Filespec[] EndOfLine
    # line __LINE__ Filespec[] EndOfLine
```

```text
Filespec:
    " DoubleQuotedCharacters[] "
```

Special token sequences are processed by the lexical analyzer, may
        appear between any other tokens, and do not affect the syntax
        parsing.

Special token sequences are terminated by the first newline that
            follows the first `#` token at the beginning of the sequence.

There is currently only one special token sequence, `#line`.

This sets the line number of the next source line to IntegerLiteral, and optionally the current source file name to Filespec, beginning with the next line of source text.

For example:

```d
int #line 6 "pkg/mod.d"
x;  // this is now line 6 of file pkg/mod.d
```

> **Implementation-defined:**
>
> The source file and line number is typically used for printing error messages
>         and for mapping generated code back to the source for the symbolic
>         debugging output.
