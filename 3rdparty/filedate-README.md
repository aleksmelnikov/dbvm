# filedate

Save and restore file/directory timestamps in a git repository.

When you clone, checkout or extract an archive, all files get the current timestamp.
This utility saves the original timestamps and restores them later — useful for `make`
which relies on mtime to determine what needs rebuilding.

## How it works

1. **Save** — walks the directory tree, reads each file's mtime, writes a metafile.
2. **Restore** — reads the metafile, sets each file's mtime back via `utime()`.

Timestamps are stored in UTC (`YYYY-MM-DDThh:mm:ssZ`) so the result is timezone-independent.

## Usage

### Standalone

```bash
# Compile
gcc -o filedate filedate.c

# Save timestamps
./filedate save    /path/to/directory /path/to/.git_file_dates_<name>

# Restore timestamps
./filedate restore /path/to/directory /path/to/.git_file_dates_<name>
```

### Flags

| Flag | save | restore | Description |
|------|------|---------|-------------|
| `-v`, `--verbose` | yes | yes | Print each file and its timestamp |
| `--dry-run` | yes | yes | Show what would happen without making changes |

**save -v** — prints each file and the date being written to the metafile:

```
src/main.c    2008-11-19T16:57:30Z
README        2008-11-03T18:54:12Z
```

**restore -v** — prints current date vs. new date, `=` if equal, `->` if different:

```
src/main.c    2025-12-31T21:00:00Z -> 2008-11-19T16:57:30Z
README        2008-11-03T18:54:12Z = 2008-11-03T18:54:12Z
```

**save --dry-run** — prints the list without creating the metafile.

**restore --dry-run** — prints what would change without touching file timestamps.

Flags can be combined: `-v --dry-run` shows the full list and makes no changes.

### With CMake

```bash
cmake -DPROJECT_DIR=path/to/dir -DACTION=save    -P git-time-external.cmake
cmake -DPROJECT_DIR=path/to/dir -DACTION=restore -P git-time-external.cmake
```

Optional CMake variables: `-DVERBOSE=ON`, `-DDRY_RUN=ON`.

The CMake script compiles `filedate` automatically on first run.

## Example workflow

```bash
# 1. Save timestamps of an external library
./filedate save third_party/libfoo-1.0 .git_file_dates_libfoo-1.0

# 2. Commit the metafile to your repo
git add .git_file_dates_libfoo-1.0

# 3. After clone/checkout, restore timestamps
git submodule update --init   # or just clone
./filedate restore third_party/libfoo-1.0 .git_file_dates_libfoo-1.0

# 4. Now make won't rebuild unchanged files
make
```

## Metafile format

One entry per line:

```
YYYY-MM-DDThh:mm:ssZ|relative/path/to/file
```

Example:

```
2008-11-03T18:54:12Z|README
2008-12-11T22:05:50Z|configure
2008-12-11T22:07:37Z|src
```

Both files and directories are included.

## Requirements

- C89 compiler (gcc, clang, MSVC)
- POSIX: `utime`, `stat` (Linux, macOS, *BSD)
- Windows: `FindFirstFileA`, `_utime`, `SetFileTime` for directories (limited UTF-8 support)

## Platform notes

| Platform | File walk | utime | UTF-8 filenames |
|----------|-----------|-------|-----------------|
| Linux    | opendir   | utime | Full support    |
| macOS    | opendir   | utime | Full support    |
| Windows  | FindFirstFileA | _utime | ANSI codepage only |

Windows: non-ASCII filenames (CJK, Cyrillic, etc.) may not work correctly.
Linux/macOS: no limitations.
