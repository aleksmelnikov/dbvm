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
#include <stdlib.h>
#include <string.h>
#include <time.h>
#include <utime.h>
#include <sys/stat.h>

#ifdef _WIN32
#include <windows.h>
#define PATH_SEP '\\'
#else
#include <dirent.h>
#define PATH_SEP '/'
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
static void write_entry(FILE *out, const char *path, const struct stat *st) {
    struct tm *tm = gmtime(&st->st_mtime);
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
    struct utimbuf ut;

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

    ut.actime  = epoch;
    ut.modtime = epoch;
    return (utime(fullpath, &ut) == 0) ? 1 : 0;
}

/* ---------- iterative walk (heap stack) ---------- */

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
    s->items[s->top++] = strdup(path);
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
        WIN32_FIND_DATAA fd;
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
                char newrel[4096];
                if (rel[0])
                    snprintf(newrel, sizeof(newrel), "%s%c%s", rel, PATH_SEP, fd.cFileName);
                else
                    snprintf(newrel, sizeof(newrel), "%s", fd.cFileName);

                char fullpath[4096];
                snprintf(fullpath, sizeof(fullpath), "%s%c%s", base, PATH_SEP, newrel);
                struct _stat st;
                if (_stat(fullpath, &st) == 0)
                    write_entry(out, newrel, (const struct stat *)&st);

                stack_push(&stack, newrel);
            } else {
                char filepath[4096];
                if (rel[0])
                    snprintf(filepath, sizeof(filepath), "%s%c%s", rel, PATH_SEP, fd.cFileName);
                else
                    snprintf(filepath, sizeof(filepath), "%s", fd.cFileName);

                char fullpath[4096];
                snprintf(fullpath, sizeof(fullpath), "%s%c%s", base, PATH_SEP, filepath);
                struct _stat st;
                if (_stat(fullpath, &st) != 0) continue;

                write_entry(out, filepath, (const struct stat *)&st);
                (*count)++;
            }
        } while (FindNextFileA(h, &fd));
        FindClose(h);
        free(rel);
    }

    free(stack.items);
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
        DIR *d;
        struct dirent *ent;

        if (rel[0])
            snprintf(dirpath, sizeof(dirpath), "%s%c%s", base, PATH_SEP, rel);
        else
            snprintf(dirpath, sizeof(dirpath), "%s", base);

        d = opendir(dirpath);
        if (!d) { free(rel); continue; }

        while ((ent = readdir(d)) != NULL) {
            if (strcmp(ent->d_name, ".") == 0 || strcmp(ent->d_name, "..") == 0)
                continue;

            char fullpath[4096];
            snprintf(fullpath, sizeof(fullpath), "%s%c%s", dirpath, PATH_SEP, ent->d_name);

            struct stat st;
            if (stat(fullpath, &st) != 0) continue;

            if (S_ISDIR(st.st_mode)) {
                char newrel[4096];
                if (rel[0])
                    snprintf(newrel, sizeof(newrel), "%s%c%s", rel, PATH_SEP, ent->d_name);
                else
                    snprintf(newrel, sizeof(newrel), "%s", ent->d_name);

                write_entry(out, newrel, &st);
                stack_push(&stack, newrel);
            } else {
                char filepath[4096];
                if (rel[0])
                    snprintf(filepath, sizeof(filepath), "%s%c%s", rel, PATH_SEP, ent->d_name);
                else
                    snprintf(filepath, sizeof(filepath), "%s", ent->d_name);

                write_entry(out, filepath, &st);
                (*count)++;
            }
        }
        closedir(d);
        free(rel);
    }

    free(stack.items);
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
    FILE *fp = fopen(metafile, "r");
    if (!fp) {
        fprintf(stderr, "Error: cannot read %s\n", metafile);
        return 1;
    }

    int count = 0;
    char line[4096];

    while (fgets(line, sizeof(line), fp)) {
        size_t len = strlen(line);
        while (len > 0 && (line[len-1] == '\n' || line[len-1] == '\r'))
            line[--len] = 0;
        if (len == 0) continue;

        char *pipe = strchr(line, '|');
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
