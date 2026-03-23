# Commit Message Convention

Сommit message format:
`<type>(<scope>): <subject> -- <file_or_folder>`

### Types
- **build**: Changes that affect the build system or external deps.
- **chore**: Routine tasks, maintenance, or tool updates.
- **ci**: Changes to CI configuration files and scripts.
- **docs**: Documentation only changes.
- **feat**: A new feature for the user.
- **fix**: A bug fix or resource leak fix.
- **init**: Initial commit or project initialization.
- **perf**: A code change that improves performance or memory usage.
- **refact**: Code change that neither fixes a bug nor adds a feature.
- **research**: Technical research, experiments, investigating new approaches and solutions.
- **revert**: Reverts a previous commit.
- **sec**: Security-related fixes or improvements.
- **style**: Changes that do not affect the meaning of the code.
- **test**: Adding missing tests or correcting existing tests.

### Formatting Rules
- **Scope** (optional): Logical module or area (e.g., `network`, `api`).
- **Subject**: Brief description of the changes in imperative mood.
- **File/Folder** (optional): Mention 1-2 key files or the folder name after ` -- `.

### Examples
- `feat: add command line arguments support -- main.cpp`
- `fix(io): resolve null pointer dereference -- logger.h`
- `build: link external threading library -- CMakeLists.txt`
- `refact(parser): simplify state machine logic -- parser.cpp, parser.h`
- `style: apply clang-format -- /src/core/`

