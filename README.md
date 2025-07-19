

# `bookdb`

**Your Shell's Missing Database: A simple, context-aware key-value store.**

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build: Passing](https://img.shields.io/badge/build-passing-brightgreen.svg)]()
[![Version: 1.0.0](https://img.shields.io/badge/version-1.0.0-blue.svg)]()

`bookdb` is a command-line utility that provides a persistent, namespaced key-value store for your shell scripts and applications. Tired of messy `.env` files, complex config parsers, or writing state to temporary files? `bookdb` solves this by giving you a clean, robust, and centralized way to manage state, all powered by the ubiquitous `sqlite3`.

Think of it as a system registry or a simple NoSQL database, but built from the ground up for the command line.

### Core Features

*   **Persistent Storage:** Your data is safely stored in a `sqlite3` database, surviving reboots and new shell sessions.
*   **Hierarchical Namespaces:** Organize your variables into `Projects` and `Key-Value Stores` to prevent conflicts between different applications.
*   **Context-Aware "Cursor":** Set your active context once and all subsequent commands run within that namespace, just like being `cd`-ed into a directory.
*   **Clean CLI Interface:** All SQL complexity is abstracted away into simple, intuitive commands like `getv`, `setv`, and `ls`.
*   **Built on BASHFX Principles:** Designed to be a "good citizen" on your system. It's self-contained, respects your `$HOME` directory, and is transparent in its operation.

## Installation

**Prerequisite:** You must have `sqlite3` installed and available in your `PATH`.
You can check this by running `command -v sqlite3`.

```bash
# 1. Clone the repository
git clone https://github.com/your-username/bookdb.git
cd bookdb

# 2. Run the installer
# This will create the necessary directories and database file in ~/.local/
./bookdb install

# 3. Enable the 'bookdb' command
# The installer created a file to set up your environment. To make it active,
# add the following line to the end of your shell profile (~/.bashrc, ~/.zshrc, etc.).
#
# You only need to do this once.
echo 'source ~/.local/etc/bookdb/book.rc' >> ~/.bashrc # Or ~/.zshrc, etc.

# 4. Start a new shell session or source the file to begin
source ~/.bashrc
```

## Quick Start: A 60-Second Tutorial

Let's store an API key for a new project called `webapp`.

```bash
# 1. Check the status of your new installation
bookdb status
#> --- BookDB Status ---
#>   Database File: /home/user/.local/share/bookdb/bookdb.sqlite
#>   Cursor File:   /home/user/.local/state/bookdb/cursor
#>   Active Cursor: @GLOBAL.VAR.MAIN
#>   Projects:
#>     - GLOBAL

# 2. Create a new project for our webapp
bookdb new project --ns webapp

# 3. Create a 'config' namespace inside our project and store our key.
# We do this using a "context chain". This also sets our active cursor!
bookdb setv API_KEY="key-super-secret-12345" @webapp.VAR.config
#> LOG: Persisting new context to cursor: webapp.config
#> LOG: Creating new variable: 'API_KEY'

# 4. Now that our cursor is set, we don't need the full context chain.
# Let's get our key back.
bookdb getv API_KEY
#> key-super-secret-12345

# 5. Use it in a script!
api_key=$(bookdb getv API_KEY)
echo "The API key for our webapp is: ${api_key}"
#> The API key for our webapp is: key-super-secret-12345
```

## Understanding Contexts & The Cursor

The most powerful feature of `bookdb` is its context-aware cursor. A **context chain** is a simple string that points to a specific namespace.

```
@<Project_Namespace>.VAR.<Key-Value_Namespace>
 \___________________/     \__________________/
          |                        |
     Top-level container     A sub-folder for
      (e.g., a project)       related variables
```

When you provide a context chain with a command (like in the Quick Start), `bookdb` does two things:
1.  Executes the command in that specific context.
2.  **Saves that context as your new active cursor.**

This means all future commands will run in that context by default, saving you from repetitive typing. You can always see your current context with `bookdb cursor`.

## Command Reference

### Core Commands

| Command           | Description                                             | Example                                    |
| ----------------- | ------------------------------------------------------- | ------------------------------------------ |
| `status`          | Display a dashboard of the system's state and projects. | `bookdb status`                            |
| `cursor`          | Print the current active cursor chain.                  | `bookdb cursor`                            |
| `install`         | Safely create or verify the `bookdb` installation.      | `bookdb install`                           |
| `reset [-y]`      | **DELETE ALL DATA** and reset `bookdb` to a clean state.  | `bookdb reset --yes`                       |
| `backup`          | Create a full, timestamped backup in your home dir.     | `bookdb backup`                            |

### Variable Management

| Command           | Description                                             | Example                                    |
| ----------------- | ------------------------------------------------------- | ------------------------------------------ |
| `getv <KEY>`      | Get the value of a variable in the current context.     | `api_key=$(bookdb getv API_KEY)`           |
| `setv <KEY=VALUE>`| Create or update a variable in the current context.     | `bookdb setv USER="alex"`                    |
| `delv <KEY>`      | Delete a variable from the current context.             | `bookdb delv OLD_TOKEN`                    |
| `ls`              | List all variables in the current key-value namespace.  | `bookdb ls`                                |

### Namespace Management

| Command                       | Description                                                     | Example                                      |
| ----------------------------- | --------------------------------------------------------------- | -------------------------------------------- |
| `new project --ns <name>`     | Create a new top-level project.                                 | `bookdb new project --ns my-cli-tool`        |
| `new keyval --ns <name>`      | Create a new key-value store within the current project.        | `bookdb new keyval --ns user_prefs`          |
| `del project --ns <name>`     | **Permanently delete a project and all its contents.**          | `bookdb del project --ns old-project`        |
| `del keyval --ns <name>`      | **Permanently delete a key-value store and all its variables.** | `bookdb del keyval --ns cache`               |
| `ls project`                  | List all available projects.                                    | `bookdb ls project`                          |
| `ls vars`                     | List all key-value stores within the current project.           | `bookdb ls vars`                             |

<br>

<details>
<summary><strong>A Note on Philosophy: BASHFX</strong></summary>

`bookdb` is built according to a small set of principles called **BASHFX**, designed to make shell tools powerful without being rude. For you as a user, this means:

*   **Self-Contained:** All installation artifacts (the database, config files, etc.) live inside a single root directory: `~/.local`.
*   **Invisible:** `bookdb` will never create new dotfiles (`.bookdb`, etc.) in your `$HOME` directory. It keeps its mess in its own room.
*   **Rewindable:** Every action should have an `undo`. The `reset` command provides a clean way to completely remove `bookdb` from your system, and the `backup` command helps protect your data.
*   **Friendly:** The tool should be proactive in communicating its state. Commands like `status` and `cursor`, and the use of clear log messages, are designed to keep you informed.

</details>

## Development

If you wish to contribute or modify `bookdb`:

*   Clone the repository as described in the installation.
*   The `bookdb dev_setup` command provides a safe way to reset the environment and populate it with a standard set of test data. This is useful for testing changes.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
