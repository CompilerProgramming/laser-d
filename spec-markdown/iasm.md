---
title: Inline assembler
status: rejected
source: ../spec/iasm.dd
---

# Inline Assembly (Excluded)

> **Laser-D normative:**
>
> Laser-D source cannot contain inline assembly. The frontend
> recognizes assembly syntax only to issue a Laser-D diagnostic and does not
> lower an assembly statement to the backend.

## <a id="rejected-forms"></a>Rejected Forms

> **Excluded from Laser-D:** Both inline-assembly families are rejected:

- D-style `asm { ... }`

GCC-style basic and extended assembly, including operands, constraints, clobbers, and goto labels.

The rejection is independent of target architecture, instruction set, compiler switch, or whether an instruction would otherwise be supported by the
unchanged backend.

## <a id="rationale"></a>Rationale

Inline assembly exposes target-specific instructions, registers, calling
conventions, stack rules, constraints, and optimizer interactions directly in
the language. Its behavior varies by architecture and compiler implementation
and conflicts with Laser-D's portable source-language goal.

Rejecting inline assembly also avoids maintaining two distinct assembly
grammars and their target-dependent semantic validation.

## <a id="alternatives"></a>External Implementation

Architecture-specific code may be implemented in a separately assembled
object file or a C implementation and exposed through an explicit supported
foreign-function interface.

```d
extern(C) uint rotate_left(uint value, uint count);
```

The external build defines which implementation is linked for each target.
The declaration must use a supported ABI, and the program remains responsible
for satisfying that ABI's argument, result, register, and memory rules.

## <a id="importc"></a>ImportC Boundary

Assembly appearing in ImportC input is not a Laser-D inline-assembly
feature. C compiler extensions, including assembly, remain part of the
separate ImportC audit and are not guaranteed by this chapter.

)
