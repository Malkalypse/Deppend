# Deppend

A lightweight, language-agnostic Bash script that **appends dependencies into a flat directory**, recursively resolves transitive dependencies via `deps.txt` files, and avoids duplicate downloads.

| | |
|-|-|
| **Default Base URL:** | `https://github.com/Malkalypse`
| **Default Install Directory:** | `./dependencies`
| **Requirements:** | `bash`, `git`, `curl`

***NOTE:** on Windows, install using **Git Bash** or **WSL***

If any installed dependency contains PHP files under `src/`, `Deppend` also automatically generates a shared `autoload.php` (leaving non-PHP projects untouched).


---

## Why Deppend?

Package managers like Composer, npm, and pip are great for large applications, but add overhead for small utilities and scripts, and are not well-suited for multi-language projects.

**Deppend** offers a simpler solution.

### No package manifests or registries:

Standalone Git repositories do not require manifests or metadata to be isntalled. If a repository *does* have dependencies, just list them one per line in a plain `deps.txt`.

### *Language-agnostic:*

Use the exact same workflow for PHP, Python, Bash scripts, C/C++, templates, or static assets.

### *No nesting or duplicate files:*
Unlike Git submodules, which nest inside each repository and duplicate shared dependencies, Deppend installs everything into one flat directory and skips already-installed siblings.

### *Run from anywhere with zero setup:*

Execute directly from GitHub with `curl | bash`, install it globally, or commit `deppend.sh` directly inside a repository.

### *Just plain Git:*

Every dependency is a normal `git clone`. There are no opaque caches, tarballs, or lockfile formats—you can inspect, edit, or `git pull` any dependency directly.

## Try the Example

Clone this repo and run the included example inside `example/`:

```bash
cd example
../deppend.sh
python dependencies/ShowDeppendMessage/show.py
```

---

## How To Use It

### Method 1: Install Globally (Recommended)

This allows `Deppend` to be used from any project on your machine.

#### macOS, Linux, and Windows (Git Bash / WSL)

Download `deppend.sh` once to a directory on your `PATH`:

```bash
mkdir -p ~/.local/bin
curl -fsSL https://raw.githubusercontent.com/Malkalypse/Deppend/main/deppend.sh -o ~/.local/bin/deppend
chmod +x ~/.local/bin/deppend
```

If `~/.local/bin` is not in your `PATH` yet:
- **Linux / WSL:** add it to `~/.bashrc`
- **macOS:** add it to `~/.zshrc`
- **Windows (Git Bash):** add it to `~/.bash_profile` *(Git Bash runs as a login shell and reads `~/.bash_profile` by default)*

```bash
# Example for Git Bash on Windows:
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bash_profile
source ~/.bash_profile
```

*(Alternatively, on macOS/Linux you can install directly to `/usr/local/bin/deppend`.)*

#### Windows (`cmd.exe` and PowerShell)

If you want to run `Deppend` directly from Command Prompt or PowerShell instead of Git Bash (requires [Git for Windows](https://gitforwindows.org/)):

1. Download `deppend.sh` in **`cmd.exe`**:

   ```bat
   mkdir "%USERPROFILE%\.local\bin"
   curl -fsSL https://raw.githubusercontent.com/Malkalypse/Deppend/main/deppend.sh -o "%USERPROFILE%\.local\bin\deppend.sh"
   ```

2. Create `%USERPROFILE%\.local\bin\deppend.cmd` with the following line:

   ```bat
   @"C:\Program Files\Git\bin\bash.exe" "%~dp0deppend.sh" %*
   ```

3. Add `%USERPROFILE%\.local\bin` to your Windows **User `PATH`** (Start → *Edit environment variables for your account* → `Path` → New), then open a new terminal.

#### Running Globally

Once installed, run `Deppend` from any project root:

```bash
deppend              # installs from ./deps.txt
deppend Enumerial
deppend -d vendor Enumerial
deppend -u
```

---

### Method 2: Download Into a Specific Project

1. Download a local copy of `deppend.sh` into your project root:

   ```bash
   curl -fsSLO https://raw.githubusercontent.com/Malkalypse/Deppend/main/deppend.sh
   chmod +x deppend.sh
   ```

2. Run it inside that project:

   ```bash
   ./deppend.sh Enumerial
   ```

   *(Or run `bash deppend.sh Enumerial` without `chmod +x`.)*

#### Method 2A: Include `deppend.sh` Inside a Repository

If you want collaborators to set up dependencies without needing `Deppend` installed globally (or relying on `curl`), commit `deppend.sh` alongside your project and ignore the downloaded `dependencies/` folder.

1. Add `deppend.sh` to your project root (`chmod +x deppend.sh`).
2. Add the install folder to `.gitignore`:

   ```gitignore
   dependencies/
   ```

3. Optionally include a `deps.txt` in your project root—running `./deppend.sh` with no arguments will automatically install everything listed in `./deps.txt`:

   ```bash
   ./deppend.sh
   ```

Collaborators can then clone your repo and pull all required dependencies (and updates with `./deppend.sh -u`) using the exact version of `deppend.sh` committed to the project.

---

### Method 3: Run Directly From GitHub (No Install)

Run `Deppend` from the root of any project without downloading or cloning it first:

```bash
curl -fsSL https://raw.githubusercontent.com/Malkalypse/Deppend/main/deppend.sh | bash -s -- Enumerial
```

Or read `./deps.txt` in the current directory:

```bash
curl -fsSL https://raw.githubusercontent.com/Malkalypse/Deppend/main/deppend.sh | bash
```

With options:

```bash
# Install into a custom folder (e.g. packages/)
curl -fsSL https://raw.githubusercontent.com/Malkalypse/Deppend/main/deppend.sh | bash -s -- -d packages Enumerial

# Override the base Git URL
curl -fsSL https://raw.githubusercontent.com/Malkalypse/Deppend/main/deppend.sh | bash -s -- -b https://github.com/OtherUser SomeLib

# Update all installed dependencies
curl -fsSL https://raw.githubusercontent.com/Malkalypse/Deppend/main/deppend.sh | bash -s -- -u
```

---

## Options

```text
Usage: deppend [options] <RepoOrUrl> [...]

Options:
  -b, --base <url>    Override base Git URL (default: https://github.com/Malkalypse)
  -d, --dir <path>    Override install directory (default: ./dependencies)
  -u, --update        Pull latest changes for already-installed dependencies
  -h, --help          Show this help message
```

If no repository arguments are provided (and `-u` is not set), `Deppend` automatically looks for `./deps.txt` in the current directory.

You can also pass full Git URLs directly (mixed with short names if needed):

```bash
deppend SomeLib https://github.com/OtherUser/AnotherLib.git
```

---

## Making a Repository Compatible With `deppend`

`Deppend` works with any repository structure and any language.

If a repository depends on other repositories, add a `deps.txt` file at its root listing each dependency one per line—either as short names (resolved against `--base`) or full Git URLs:

```text
# Lines starting with # are ignored
MalkalypseLib
https://github.com/OtherUser/AnotherLib.git
```

All dependencies are cloned as flat siblings under `./dependencies/` (or your `--dir` path), and already-installed siblings are skipped automatically to prevent duplicate diamond dependencies.

---

## PHP Projects (Automatic Autoloader)

If any installed dependency contains `.php` files inside a `src/` directory, `Deppend` automatically generates `dependencies/autoload.php` (or `<target-dir>/autoload.php`) if it doesn't already exist.

1. Place PHP source files under `src/` matching their namespace:

   ```text
   MyPackage/
   ├── deps.txt                  (optional)
   └── src/
       └── MyNamespace/
           └── MyClass.php
   ```

2. Include the generated autoloader once in your PHP entrypoint:

   ```php
   <?php
   require_once __DIR__ . '/dependencies/autoload.php';
   ```

The autoloader scans `*/src/` across all installed sibling folders, mapping class names and namespaces directly to file paths, e.g., `Enumerial` → `dependencies/Enumerial/src/Enumerial.php`.

(Non-PHP projects will not have `autoload.php` created.)

## License

Copyright © 2026 Kevin Mackey. All Rights Reserved.

You are free to download, use, and redistribute unmodified copies of this software for personal or commercial purposes, provided `LICENSE.md` and all copyright notices are kept intact. Modifying the source code or distributing modified versions is not permitted without prior written permission. See [LICENSE.md](LICENSE.md) for the full terms.

