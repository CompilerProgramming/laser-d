/**
 * Bindings for the C <string.h> APIs supported by Laser-D.
 *
 * Derived from druntime's core.stdc.string.
 */
module core.stdc.string;

import core.stdc.stddef : size_t;

extern(C)
{
    const(void)* memchr(const void* memory, int value, size_t count);
    int memcmp(const void* left, const void* right, size_t count);
    void* memcpy(void* destination, const void* source, size_t count);
    void* memmove(void* destination, const void* source, size_t count);
    void* memset(void* destination, int value, size_t count);

    char* strcat(char* destination, const char* source);
    const(char)* strchr(const char* text, int value);
    int strcmp(const char* left, const char* right);
    int strcoll(const char* left, const char* right);
    char* strcpy(char* destination, const char* source);
    size_t strcspn(const char* text, const char* rejected);
    const(char)* strerror(int error);
    size_t strlen(const char* text);
    char* strncat(char* destination, const char* source, size_t count);
    int strncmp(const char* left, const char* right, size_t count);
    char* strncpy(char* destination, const char* source, size_t count);
    const(char)* strpbrk(const char* text, const char* accepted);
    const(char)* strrchr(const char* text, int value);
    size_t strspn(const char* text, const char* accepted);
    const(char)* strstr(const char* text, const char* sought);
    char* strtok(char* text, const char* delimiters);
    size_t strxfrm(char* destination, const char* source, size_t count);
}
