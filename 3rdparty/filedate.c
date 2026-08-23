/*
 * filedate.c - Save and restore file and directory timestamps.
 *
 * C89/C90 compatible. No C99+ features used.
 * Dependencies: utime, stat - POSIX (available on all major platforms).
 *
 * Metafile format: YYYY-MM-DDThh:mm:ssZ|relative/path  (UTC)
 *
 * Build:  gcc -o filedate filedate.c   /  cl filedate.c
 * Usage:  filedate save    <directory> <metafile>
 *         filedate restore <directory> <metafile>
 *
 * Copyright (c) 2026 dbvm
 *
 */

#include <stdio.h>
#if defined(__STRICT_ANSI__)
/* snprintf() is C99; strict C90 modes (-std=c89, -ansi) hide its
 * prototype although every supported libc provides the symbol.
 * Declare it here so -std=c89 -pedantic builds cleanly.
 * (MSVC never defines __STRICT_ANSI__, so this stays inactive there.) */
extern int snprintf(char *s, size_t n, const char *fmt, ...);
#endif
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <sys/stat.h>

#ifdef _WIN32
#include <windows.h>
#include <sys/utime.h>
/* MSVC lacks the POSIX S_ISDIR() test macro; synthesize it from the
 * CRT's _S_IFMT/_S_IFDIR mode bits. (MinGW already defines S_ISDIR,
 * hence the #ifndef guard.) */
#ifndef S_ISDIR
#define S_ISDIR(m) (((m) & _S_IFMT) == _S_IFDIR)
#endif
#define PATH_SEP '\\'
/* MSVC exposes the POSIX time APIs under underscore-prefixed names. */
#define FILEDATE_UTIMBUF struct _utimbuf
#define FILEDATE_UTIME   _utime

/* _utime() cannot open directories on Windows; the documented way to
 * touch a directory's times is CreateFile with FILE_FLAG_BACKUP_SEMANTICS
 * plus SetFileTime(). No administrator rights are required. */
static int fd_set_dir_mtime(const char *path, time_t epoch) {
    HANDLE h;
    FILETIME ft;
    ULONGLONG wintime = ((ULONGLONG)epoch + 11644473600ULL) * 10000000ULL;
    int ok;

    ft.dwLowDateTime  = (DWORD)(wintime & 0xFFFFFFFFULL);
    ft.dwHighDateTime = (DWORD)(wintime >> 32);

    h = CreateFileA(path, FILE_WRITE_ATTRIBUTES,
                    FILE_SHARE_READ | FILE_SHARE_WRITE, NULL,
                    OPEN_EXISTING, FILE_FLAG_BACKUP_SEMANTICS, NULL);
    if (h == INVALID_HANDLE_VALUE) {
        fprintf(stderr, "Warning: cannot open directory: %s\n", path);
        return 0;
    }
    ok = SetFileTime(h, NULL, &ft, &ft);   /* access + write times */
    CloseHandle(h);
    if (!ok)
        fprintf(stderr, "Warning: cannot set time: %s\n", path);
    return ok ? 1 : 0;
}
#else
#include <utime.h>
#include <dirent.h>
#define PATH_SEP '/'
#define FILEDATE_UTIMBUF struct utimbuf
#define FILEDATE_UTIME   utime
#endif

static int g_verbose;
static int g_dryrun;

/* Gregorian leap year: divisible by 4, except centuries, except 400-years */
static int is_leap(int y) {
    return (y % 4 == 0 && y % 100 != 0) || (y % 400 == 0);
}

/* Convert UTC struct tm to time_t without depending on local timezone.
 * Accounts for leap years in the Gregorian calendar (4/100/400 rules). */
static time_t my_timegm(struct tm *t) {
    static const int mdays[] = {0,31,59,90,120,151,181,212,243,273,304,334};
    int year = t->tm_year + 1900;
    int mon  = t->tm_mon;
    int day  = t->tm_mday;
    long days;

    days = (long)(year - 1970) * 365;
    days += (year - 1) / 4 - 1969 / 4;       /* +1 day per 4 years       */
    days -= (year - 1) / 100 - 1969 / 100;   /* -1 day per 100 years     */
    days += (year - 1) / 400 - 1969 / 400;   /* +1 day per 400 years     */
    days += mdays[mon];
    if (mon > 1 && is_leap(year)) days++;
    days += day - 1;
    return days * 86400 + t->tm_hour * 3600 + t->tm_min * 60 + t->tm_sec;
}

/* Write one timestamp|path line to the metafile (skipped if out is NULL). */
static void write_entry(FILE *out, const char *path, time_t mtime) {
    struct tm *tm = gmtime(&mtime);
    char date_str[32];
    if (!tm) return;
    snprintf(date_str, sizeof(date_str),
             "%04d-%02d-%02dT%02d:%02d:%02dZ",
             tm->tm_year + 1900, tm->tm_mon + 1, tm->tm_mday,
             tm->tm_hour, tm->tm_min, tm->tm_sec);
    if (out)
        fprintf(out, "%s|%s\n", date_str, path);
    if (g_verbose)
        printf("%-50s  %s\n", path, date_str);
}

/* Parse a timestamp string and set the file's mtime via utime().
 * In verbose mode prints current -> new date.
 * In dry-run mode skips the actual utime call. */
static int apply_entry(const char *dir, const char *ts, const char *relpath) {
    struct tm t;
    struct stat st;
    char fullpath[4096];
    time_t epoch;
    FILEDATE_UTIMBUF ut;

    memset(&t, 0, sizeof(t));
    if (sscanf(ts, "%4d-%2d-%2dT%2d:%2d:%2d",
               &t.tm_year, &t.tm_mon, &t.tm_mday,
               &t.tm_hour, &t.tm_min, &t.tm_sec) != 6)
        return 0;
    t.tm_year -= 1900;
    t.tm_mon  -= 1;

    snprintf(fullpath, sizeof(fullpath), "%s%c%s", dir, PATH_SEP, relpath);
    epoch = my_timegm(&t);

    if (g_verbose) {
        if (stat(fullpath, &st) == 0) {
            struct tm *cur = gmtime(&st.st_mtime);
            char cur_str[32], new_str[32];
            const char *arrow;
            if (cur) {
                snprintf(cur_str, sizeof(cur_str),
                         "%04d-%02d-%02dT%02d:%02d:%02dZ",
                         cur->tm_year + 1900, cur->tm_mon + 1, cur->tm_mday,
                         cur->tm_hour, cur->tm_min, cur->tm_sec);
            } else {
                snprintf(cur_str, sizeof(cur_str), "unknown");
            }
            snprintf(new_str, sizeof(new_str), "%s", ts);
            arrow = (st.st_mtime == epoch) ? "=" : "->";
            printf("%-50s  %s %s %s\n", relpath, cur_str, arrow, new_str);
        } else {
            printf("%-50s  (stat failed) -> %s\n", relpath, ts);
        }
    }

    if (g_dryrun)
        return 1;

#ifdef _WIN32
    /* Directory times need the SetFileTime() path (_utime fails on dirs). */
    if (stat(fullpath, &st) == 0 && S_ISDIR(st.st_mode))
        return fd_set_dir_mtime(fullpath, epoch);
#endif

    ut.actime  = epoch;
    ut.modtime = epoch;
    if (FILEDATE_UTIME(fullpath, &ut) != 0) {
        fprintf(stderr, "Warning: cannot set time: %s\n", fullpath);
        return 0;
    }
    return 1;
}

/* ---------- iterative walk (heap stack) ---------- */

/* Portable string duplication (strdup is non-standard on MSVC). */
static char *fd_strdup(const char *s) {
    size_t n = strlen(s) + 1;
    char *p = (char *)malloc(n);
    if (p) memcpy(p, s, n);
    return p;
}

/* Dynamic string stack for iterative directory traversal. */
typedef struct {
    char **items;
    int top;
    int cap;
} strstack;

/* Initialize stack with default capacity. */
static void stack_init(strstack *s) {
    s->cap = 64;
    s->top = 0;
    s->items = (char **)malloc(s->cap * sizeof(char *));
}

/* Push a string copy onto the stack. */
static void stack_push(strstack *s, const char *path) {
    if (s->top == s->cap) {
        s->cap *= 2;
        s->items = (char **)realloc(s->items, s->cap * sizeof(char *));
    }
    s->items[s->top++] = fd_strdup(path);
}

/* Pop and return the top string (caller must free). */
static char *stack_pop(strstack *s) {
    return s->items[--s->top];
}

/* Free all stack memory. */
static void stack_free(strstack *s) {
    int i;
    for (i = 0; i < s->top; i++) free(s->items[i]);
    free(s->items);
    s->items = 0;
    s->top = s->cap = 0;
}

#ifdef _WIN32

/* Iteratively walk a directory tree, write timestamps to metafile (Win32). */
static void walk(const char *base, FILE *out, int *count) {
    strstack stack;
    stack_init(&stack);
    stack_push(&stack, "");

    while (stack.top > 0) {
        char *rel = stack_pop(&stack);
        char dirpath[4096];
        char pattern[4096];
        char newrel[4096];
        char fullpath[4096];
        char filepath[4096];
        WIN32_FIND_DATAA fd;
        struct _stat st;
        HANDLE h;

        if (rel[0])
            snprintf(dirpath, sizeof(dirpath), "%s%c%s", base, PATH_SEP, rel);
        else
            snprintf(dirpath, sizeof(dirpath), "%s", base);

        snprintf(pattern, sizeof(pattern), "%s%c*", dirpath, PATH_SEP);

        h = FindFirstFileA(pattern, &fd);
        if (h == INVALID_HANDLE_VALUE) { free(rel); continue; }

        do {
            if (fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
                if (strcmp(fd.cFileName, ".") == 0 || strcmp(fd.cFileName, "..") == 0)
                    continue;
                if (rel[0])
                    snprintf(newrel, sizeof(newrel), "%s%c%s", rel, PATH_SEP, fd.cFileName);
                else
                    snprintf(newrel, sizeof(newrel), "%s", fd.cFileName);

                snprintf(fullpath, sizeof(fullpath), "%s%c%s", base, PATH_SEP, newrel);
                if (_stat(fullpath, &st) == 0)
                    write_entry(out, newrel, st.st_mtime);

                stack_push(&stack, newrel);
            } else {
                if (rel[0])
                    snprintf(filepath, sizeof(filepath), "%s%c%s", rel, PATH_SEP, fd.cFileName);
                else
                    snprintf(filepath, sizeof(filepath), "%s", fd.cFileName);

                snprintf(fullpath, sizeof(fullpath), "%s%c%s", base, PATH_SEP, filepath);
                if (_stat(fullpath, &st) != 0) continue;

                write_entry(out, filepath, st.st_mtime);
                (*count)++;
            }
        } while (FindNextFileA(h, &fd));
        FindClose(h);
        free(rel);
    }

    stack_free(&stack);
}

#else

/* Iteratively walk a directory tree, write timestamps to metafile (POSIX). */
static void walk(const char *base, FILE *out, int *count) {
    strstack stack;
    stack_init(&stack);
    stack_push(&stack, "");

    while (stack.top > 0) {
        char *rel = stack_pop(&stack);
        char dirpath[4096];
        char newrel[4096];
        char fullpath[4096];
        char filepath[4096];
        DIR *d;
        struct dirent *ent;
        struct stat st;

        if (rel[0])
            snprintf(dirpath, sizeof(dirpath), "%s%c%s", base, PATH_SEP, rel);
        else
            snprintf(dirpath, sizeof(dirpath), "%s", base);

        d = opendir(dirpath);
        if (!d) { free(rel); continue; }

        while ((ent = readdir(d)) != NULL) {
            if (strcmp(ent->d_name, ".") == 0 || strcmp(ent->d_name, "..") == 0)
                continue;

            snprintf(fullpath, sizeof(fullpath), "%s%c%s", dirpath, PATH_SEP, ent->d_name);

            if (stat(fullpath, &st) != 0) continue;

            if (S_ISDIR(st.st_mode)) {
                if (rel[0])
                    snprintf(newrel, sizeof(newrel), "%s%c%s", rel, PATH_SEP, ent->d_name);
                else
                    snprintf(newrel, sizeof(newrel), "%s", ent->d_name);

                write_entry(out, newrel, st.st_mtime);
                stack_push(&stack, newrel);
            } else {
                if (rel[0])
                    snprintf(filepath, sizeof(filepath), "%s%c%s", rel, PATH_SEP, ent->d_name);
                else
                    snprintf(filepath, sizeof(filepath), "%s", ent->d_name);

                write_entry(out, filepath, st.st_mtime);
                (*count)++;
            }
        }
        closedir(d);
        free(rel);
    }

    stack_free(&stack);
}

#endif

/* Save all file/dir timestamps from directory into a metafile. */
static int save_dates(const char *dir, const char *metafile) {
    FILE *out = NULL;
    int count = 0;

    if (!g_dryrun) {
        out = fopen(metafile, "w");
        if (!out) {
            fprintf(stderr, "Error: cannot write %s\n", metafile);
            return 1;
        }
    }

    walk(dir, out, &count);

    if (out) fclose(out);

    if (g_dryrun)
        printf("[dry-run] %d entries (no file written)\n", count);
    else
        printf("[save] %d entries -> %s\n", count, metafile);
    return 0;
}

/* Read metafile and restore timestamps for all listed files/dirs. */
static int restore_dates(const char *dir, const char *metafile) {
    FILE *fp;
    int count = 0;
    size_t len;
    char line[4096];
    char *pipe;

    fp = fopen(metafile, "r");
    if (!fp) {
        fprintf(stderr, "Error: cannot read %s\n", metafile);
        return 1;
    }

    while (fgets(line, sizeof(line), fp)) {
        len = strlen(line);
        while (len > 0 && (line[len-1] == '\n' || line[len-1] == '\r'))
            line[--len] = 0;
        if (len == 0) continue;

        pipe = strchr(line, '|');
        if (!pipe) continue;
        *pipe = 0;

        if (apply_entry(dir, line, pipe + 1)) count++;
    }

    fclose(fp);
    if (g_dryrun)
        printf("[dry-run] %d entries (no changes made)\n", count);
    else
        printf("[restore] %d entries\n", count);
    return 0;
}

/* Entry point: dispatch to save or restore based on arguments. */
int main(int argc, char *argv[]) {
    int i;
    const char *action   = 0;
    const char *directory = 0;
    const char *metafile  = 0;

    g_verbose = 0;
    g_dryrun  = 0;

    for (i = 1; i < argc; i++) {
        if (strcmp(argv[i], "-v") == 0 || strcmp(argv[i], "--verbose") == 0) {
            g_verbose = 1;
        } else if (strcmp(argv[i], "--dry-run") == 0) {
            g_dryrun = 1;
        } else if (!action) {
            action = argv[i];
        } else if (!directory) {
            directory = argv[i];
        } else if (!metafile) {
            metafile = argv[i];
        }
    }

    if (!action || !directory || !metafile) {
        fprintf(stderr,
            "Usage: filedate save [-v] [--dry-run] <directory> <metafile>\n"
            "       filedate restore [-v] [--dry-run] <directory> <metafile>\n");
        return 1;
    }

    if (strcmp(action, "save") == 0)
        return save_dates(directory, metafile);
    if (strcmp(action, "restore") == 0)
        return restore_dates(directory, metafile);

    fprintf(stderr, "Unknown action: %s\n", action);
    return 1;
}
