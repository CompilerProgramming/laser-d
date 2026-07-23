/**
 * Bindings for the basic C <stdio.h> APIs supported by Laser-D.
 *
 * Derived from druntime's core.stdc.stdio.
 */
module core.stdc.stdio;

import core.stdc.stddef : size_t;

extern(C) struct FILE;

enum EOF = -1;
enum SEEK_SET = 0;
enum SEEK_CUR = 1;
enum SEEK_END = 2;

extern(C)
{
    int remove(const char* filename);
    int rename(const char* oldName, const char* newName);

    FILE* fopen(const char* filename, const char* mode);
    int fclose(FILE* stream);
    int fflush(FILE* stream);

    size_t fread(void* destination, size_t size, size_t count, FILE* stream);
    size_t fwrite(const void* source, size_t size, size_t count, FILE* stream);
    int fseek(FILE* stream, long offset, int origin);
    long ftell(FILE* stream);
    void rewind(FILE* stream);

    int fgetc(FILE* stream);
    char* fgets(char* destination, int count, FILE* stream);
    int fputc(int character, FILE* stream);
    int fputs(const char* text, FILE* stream);

    int puts(const char* text);
    int printf(const char* format, ...);
    int sprintf(char* destination, const char* format, ...);
    int snprintf(char* destination, size_t count, const char* format, ...);

    int feof(FILE* stream);
    int ferror(FILE* stream);
    void clearerr(FILE* stream);
    void perror(const char* prefix);
}
