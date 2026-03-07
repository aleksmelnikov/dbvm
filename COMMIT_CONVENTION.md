# Commit Message Convention

Follow this format for all commit messages:
`<type>(<scope>): <subject> -- <file_or_folder>`

### Types
- **feat**: A new feature for the user.
- **fix**: A bug fix or resource leak fix.
- **refact**: Code change that neither fixes a bug nor adds a feature.
- **chore**: Routine tasks, maintenance, or tool updates.
- **docs**: Documentation only changes.
- **style**: Changes that do not affect the meaning of the code.
- **perf**: A code change that improves performance or memory usage.
- **test**: Adding missing tests or correcting existing tests.
- **build**: Changes that affect the build system or external deps.
- **ci**: Changes to CI configuration files and scripts.
- **revert**: Reverts a previous commit.
- **sec**: Security-related fixes or improvements.
- **init**: Initial commit or project initialization.

### Formatting Rules
- **Scope** (optional): Logical module or area (e.g., `network`, `api`).
- **Subject**: Brief description of the changes in imperative mood.
- **File/Folder** (optional): Names of the 1 or 2 most important files or the directory name after ` -- `.

### Examples
- `feat: add command line arguments support -- main.cpp`
- `fix(io): resolve null pointer dereference -- logger.h`
- `build: link external threading library -- CMakeLists.txt`
- `refact(parser): simplify state machine logic -- parser.cpp, parser.h`
- `style: apply clang-format -- /src/core/`

