---
title: Attributes
status: restricted
source: ../spec/attribute.dd
---

# Attributes

Attributes and declaration modifiers alter linkage, visibility, storage, or function semantics. Laser-D supports only attributes classified by this
chapter or another normative chapter. Lexical recognition of another D
attribute does not make it available.

## <a id="grammar"></a>Settled Grammar

```text
AttributeSpecifier:
    Attribute :
    Attribute DeclarationBlock

Attribute:
    LinkageAttribute
    VisibilityAttribute
    auto
    immutable
    ref
    static

DeclarationBlock:
    DeclDef
    { DeclDefs[] }
```

This grammar lists settled attribute-specifier forms. Each modifier is
still limited to the declaration kinds allowed by its defining chapter. In
particular, `static` does not permit mutable static storage, `ref` does
not permit reference results, and visibility is currently guaranteed only for
module imports.

## <a id="linkage"></a>Linkage Attributes

```text
LinkageAttribute:
    extern ( LinkageType )

LinkageType:
    D
    C
    C ++
```

`extern(D)` selects the native D ABI. `extern(C)` selects the target
C ABI and is the primary foreign-function interface. `extern(C++)` is
supported for free functions, function pointers, mangling, and overload sets.

```d
extern(C) int c_function(int value);
extern(C++) int cpp_function(int value);
```

> **Excluded from Laser-D:**
>
> C++ linkage does not enable C++ structs, classes, interfaces, or member functions. `extern(Objective-C)` and the Objective-C object model
> are rejected.

### <a id="namespace"></a>C++ Namespaces

> **Under review:**
>
> C++ namespace-qualified linkage and the extended
> `extern(C++, ...)` forms have not yet been classified. Simple C++
> free-function linkage does not imply support for these forms.

> **Under review:**
>
> `extern(Windows)` and `extern(System)` remain to be
> reviewed for their portable Laser-D boundary. ImportC applies the calling
> convention rules required by its C input.

## <a id="visibility_attributes"></a>Visibility Attributes

```text
VisibilityAttribute:
    private
    public
```

`private import` keeps imported symbols from being re-exported.
`public import` re-exports imported symbols. An unqualified import has the
default visibility specified by the modules chapter.

> **Under review:**
>
> General declaration visibility, `package`, `protected`, and `export` have not yet been classified. Native classes
> and interfaces are absent, so their protected-member model cannot apply.

### <a id="private"></a>`private`

On an import, `private` limits the binding to the importing module.

### <a id="public"></a>`public`

On an import, `public` makes the imported binding available to modules
that import the current module.

### <a id="package"></a>`package`

> **Under review:**
>
> Package visibility is part of the unresolved package
> module and package hierarchy review.

### <a id="export"></a>`export`

> **Under review:**
>
> Export visibility and shared-library symbol publication
> have not yet been specified for Laser-D.

## <a id="mutability"></a>Mutability and Storage Modifiers

### <a id="immutable"></a>`immutable`

`immutable` constructs a transitively immutable type or declaration as
defined by the type-qualifier chapter. It may be used for local values and for
static data whose initializer is compile-time evaluable.

### <a id="static"></a>`static`

`static` is available where a supported declaration uses static
membership or storage. Mutable module, function-static, and aggregate-static
storage is rejected; manifest constants and deeply immutable static data are
the supported static-data cases.

### <a id="auto"></a>`auto`

`auto` requests compile-time type inference from a required initializer.
It does not enable `auto ref`, safety inference, purity inference, or
inference of a rejected type.

### <a id="ref"></a>`ref`

`ref` is supported for function parameters and local reference
variables under the declaration and function rules. Reference function results
and `auto ref` are rejected.

## <a id="function-attributes"></a>Implicit Function Attributes

> **Laser-D normative:**
>
> Every Laser-D function and function type is implicitly
> `nothrow`, `@nogc`, and `@system`. The attributes are properties of
> the type even though they cannot be written in source. Functions remain
> conservatively impure.

### <a id="nothrow"></a>`nothrow`

No exception may escape a Laser-D function. Explicit `nothrow` is
rejected because it is mandatory and implicit.

### <a id="nogc"></a>`@nogc`

A Laser-D function cannot use a GC operation. Explicit `@nogc` is
rejected because it is mandatory and implicit.

### <a id="safe"></a>and `@system`

Laser-D performs no D safety inference. Every function is implicitly
`@system`; explicit `@system`, `@safe`, and `@trusted` are all
rejected. Pointer and lifetime correctness remain programmer responsibilities.

### <a id="system-variables"></a>System Variables (Excluded)

Explicit `@system` variables and fields are rejected with the explicit
safety-attribute surface. Laser-D does not distinguish a separate safety class
of variables.

### <a id="pure"></a>`pure`

> **Excluded from Laser-D:**
>
> `pure` is rejected. Laser-D functions are conservatively
> impure, so the compiler does not promise absence of externally visible state.

### <a id="property"></a>`@property`

> **Excluded from Laser-D:**
>
> `@property` is rejected. Ordinary functions and methods
> must be called with parentheses and cannot behave syntactically like fields.

## <a id="shared-storage"></a>Threading Attributes

### <a id="shared"></a>`shared`

> **Excluded from Laser-D:**
>
> `shared` is not a Laser-D type qualifier or declaration
> attribute.

### <a id="gshared"></a>`__gshared`

> **Excluded from Laser-D:**
>
> `__gshared` is rejected because D-owned mutable global
> state and native language-level threading are disabled.

### <a id="synchronized"></a>`synchronized`

> **Excluded from Laser-D:**
>
> `synchronized` declarations and statements are rejected.
> Programs may call explicit C threading and synchronization APIs.

## <a id="rejected_attributes"></a>Other Rejected Attributes

> **Excluded from Laser-D:**
>
> `@live`, `scope`, `lazy`, parameter/result
> `return`, `inout`, `const`, `final` parameters, `__rvalue`, `abstract`, `final`, and `override` are rejected in the source
> locations governed by their corresponding feature decisions.

### <a id="scope"></a>`scope`

The parameter and variable `scope` annotation is rejected. The
`scope(exit)` statement is a separate cleanup statement and remains
supported.

### <a id="scope-class-var"></a>Scope Class Instances (Excluded)

Scope-managed class instances are unavailable because `scope`, native
classes, class destruction, and language-managed allocation are all rejected.

### <a id="__rvalue"></a>`__rvalue`

`__rvalue` is rejected together with the related `__traits(isReturnOnStack)`
surface.

## <a id="uda"></a>User-Defined Attributes

### <a id="UserDefinedAttribute"></a>User-Defined Attribute Syntax (Excluded)

> **Excluded from Laser-D:**
>
> User-defined attributes are rejected in every source
> location. This includes `@(arguments)`, `@identifier`, UDA template
> instances, and UDA call expressions. Supported `__traits(getAttributes)`
> queries remain useful to generic code but return an empty sequence for ordinary
> Laser-D declarations.

## <a id="attributes_under_review"></a>Built-in Attributes Under Review

> **Under review:**
>
> The following built-in facilities are not yet Laser-D
> guarantees: `align`, `deprecated`, `@__future`, general visibility, `export`, `pragma`, and compiler-recognized special
> attributes. They remain reserved syntax while their individual reviews are
> pending.

### <a id="align"></a>`align`

#### <a id="AlignAttribute"></a>Alignment Attribute Grammar (Under Review)

Explicit alignment control remains under review. The compile-time
`.alignof` property is supported independently.

### <a id="deprecated"></a>`deprecated`

#### <a id="DeprecatedAttribute"></a>Deprecation Attribute Grammar (Under Review)

Source-level deprecation annotations and module deprecation remain under
review.

### <a id="disable"></a>`@disable`

> **Rejected in Laser-D:**
>
> Explicit `@disable` is rejected. Laser-D does not use an
> attribute to create unavailable declarations, disabled overloads, nonconstructible structs, or noncopyable structs.

### <a id="future"></a>`@__future`

The implementation-reserved future attribute is not a portability
guarantee.

### <a id="FunctionAttributeKwd"></a>Explicit Function Attribute Keywords

Explicit `nothrow` and `pure` are rejected. The first is implicit;
the second is not a Laser-D function property.

### <a id="AtAttribute"></a>At-Sign Attributes

Settled at-sign attributes are rejected: safety attributes, `@nogc`, `@live`, `@property`, and UDAs. Remaining built-in at-sign attributes are
under review.

### <a id="Property"></a>Property Attribute (Excluded)

`@property` is excluded as described under implicit function
attributes.

## <a id="class-attributes"></a>Object-Oriented Attributes

> **Excluded from Laser-D:**
>
> Class-specific uses of `abstract`, `final`, `override`, and `synchronized` are absent with native classes and
> interfaces.
