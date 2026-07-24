# Laser-D language specification

This directory is the Markdown language specification for Laser-D.

The chapters describe the language that Laser-D provides. They are not
annotated copies of the D specification and do not attempt to teach features
which Laser-D does not have. Readers migrating D code should use
[D compatibility notes](d-compatibility.md) for a consolidated description of
the differences.

The older Ddoc sources remain under [`spec/`](../spec) while the Markdown
specification becomes authoritative. During this transition, a reviewed
Markdown chapter may intentionally differ from its historical Ddoc source.

## Language

- [Lexical analysis](lex.md)
- [Modules](module.md)
- [Declarations](declaration.md)
- [Types](type.md)
- [Type qualifiers](const3.md)
- [Enums](enum.md)
- [Structs and unions](struct.md)
- [Arrays and slices](arrays.md)
- [Functions](function.md)
- [Attributes](attribute.md)
- [Expressions](expression.md)
- [Statements](statement.md)
- [Built-in properties](property.md)
- [Operator overloading](operatoroverloading.md)
- [Templates](template.md)
- [Template mixins](template-mixin.md)
- [Conditional compilation](version.md)
- [Traits](traits.md)
- [Error handling and cleanup](errors.md)

## Interoperability and platforms

- [ImportC](importc.md)
- [Portability](portability.md)

## Compatibility

- [D compatibility notes](d-compatibility.md)
