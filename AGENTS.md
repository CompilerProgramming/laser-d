# Project objective

The goal of this project is to create a cut-down version of D, named Laser-D which stands for Lesser D. 
I expect most of the changes to occur only in the language front-end. 

# Current goals

- Goal 1 - Compiler will always run win -betterC mode, this cannot be changed. Thus the language will not have GC or a runtime other than the C runtime.
- Goal 2 - Portable - language will remain portable to Windows, Linux and MacOSX, initailly x86-64. ARM64 support will be added when upstream has it. Only 64-bit platforms supported.
- Goal 3 - A new set of tests and docs will be created for the reduced scope.

# Constraints

- Compatibility requirements - we will not invent new syntax. Any progam written in Laser-D shall also be a D program.
- Areas that must not change - There will be no changes to the backend or the interface between front-end and backend.
- Testing expectations - Since this will be a subset of D, existing test suite is likely to fail. We will need to create new set of tests for the language.


# Note on making changes

- Always describe what changes will be done before making any changes.
- Do not commit
- Add language and compiler tests under compiler/test/laser-d
- Add standard-library and native-library integration tests under library/test
- Document changes in DESIGN.md
- When a language feature is identified, accepted, restricted, rejected, or changed, update the applicable language specification under spec-markdown so that it remains consistent with Laser-D's tests and implementation
- When documentation review encounters a language feature whose status has not been decided, add a distinct Undecided entry to FEATURE_STATUS.md before removing or replacing that material
- Undecided means that there is no test case in compiler/test/laser-d that proves that the feature works.
- Review comments will go into REVIEW.md
- Libraries are built using cmake for interoperability with C libs
