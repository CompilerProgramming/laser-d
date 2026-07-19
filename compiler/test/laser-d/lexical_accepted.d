// TEST_MODE: compilable

// Whitespace and all three comment forms are retained.
/+ Outer nesting comment
    /+ inner nesting comment +/
+/
/* block comment */
// line comment

enum asciiIdentifier = 1;
enum ASCIIIdentifier = 2;
enum λ = 3;
static assert(asciiIdentifier != ASCIIIdentifier);
static assert(λ == 3);

enum decimalInteger = 1_000_000;
enum binaryInteger = 0b1010_0101;
enum hexadecimalInteger = 0xCAFE_BABE;
enum unsignedInteger = 42U;
enum longInteger = 42L;
static assert(binaryInteger == 165);
static assert(hexadecimalInteger == 3_405_691_582U);
static assert(is(typeof(unsignedInteger) == uint));
static assert(is(typeof(longInteger) == long));

enum decimalFloat = 1.25;
enum exponentFloat = 1e2;
enum hexadecimalFloat = 0x1p+4;
enum floatSuffix = 1.0f;
enum realSuffix = 1.0L;
static assert(decimalFloat == 1.25);
static assert(exponentFloat == 100.0);
static assert(hexadecimalFloat == 16.0);
static assert(is(typeof(floatSuffix) == float));
static assert(is(typeof(realSuffix) == real));

enum character = 'A';
enum escapedCharacter = '\x41';
enum unicodeCharacter = '\u03BB';
enum namedCharacter = '\&copy;';
static assert(character == escapedCharacter);
static assert(unicodeCharacter == 'λ');
static assert(namedCharacter == '\u00A9');

enum quotedString = "line\n\t\"quoted\"";
enum wysiwygString = r"c:\root\file";
enum alternateWysiwygString = `c:\root\file`;
enum delimitedString = q"[outer [inner] outer]";
enum tokenString = q{ int tokenValue = 1; };
enum hexadecimalString = x"4c 61 73 65 72 2d 44";
enum wideString = "Laser-D"w;
enum dcharString = "Laser-D"d;
static assert(wysiwygString == alternateWysiwygString);
static assert(delimitedString == "outer [inner] outer");
static assert(hexadecimalString == "Laser-D");
static assert(wideString.length == 7);
static assert(dcharString.length == 7);

enum sourceFile = __FILE__;
enum sourceLine = __LINE__;
enum sourceModule = __MODULE__;
static assert(sourceFile.length != 0);
static assert(sourceLine > 0);
static assert(sourceModule.length != 0);

extern(C) int main()
{
    return 0;
}
