
# 📖`BookDB. `
*Awesomer E-N-Vs thanks to data-beez.*

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Version: 0.6.0](https://img.shields.io/badge/Version-0.6_Beta-blue.svg)]()
[![Bash Support](https://img.shields.io/badge/Bash-3.2+-red.svg)]()
[![MVP Compliant](https://img.shields.io/badge/Standards-MVP-violet.svg)]()
[![Test: OK](https://img.shields.io/badge/Test-Awesome-brightgreen.svg)]()


`bookdb` is a general purpose CLI tool for managing and sharing state across disparate tools via an ultra-light `sqlite` interface. It allows for modular, custom utilities to define their objects, relationships and interfaces within their feature scope.

**VAR Keystore**

The introductory MVP featureset for bookDB is its VAR Keystore feature, which provides expressive key-value stores for namespaced datasets. It enables novel patterns for managing state, meta information, and environment variables through its rewindable api and innovative profile switching algorithm using a mechanism called the *Cursor*. 

The innovative featuers of VAR, abstract cumbersome SQL queries into powerful commands that express intent, and restores context through a virtual stack  concept called *Context Chains*, in an interface that is friendly for both command lines and automation.


<br >


## 📦 Bookdb's VAR Core Features

**Persistent Storage:** Your data is squirreled away ~~stored~~ in a `sqlite3` database, surviving reboots, new shell sessions, and dare I say the rapture. As an sqlite file your data is easy to move and backup using your prefered tools.
<br >

**Hierarchical Namespaces:** Organize your variables into `Projects` and `Key-Value Stores` to prevent conflict between angry applications using baseball bats as greeting wands.
<br >

**Context-Aware "Cursor":** Set your active context once and all subsequent commands run within that namespace, just like being ~ `cd`-ed into a directory.
<br >

**Powerful I/O:** Easily `import` and `export` variables from standard `.env` files, enabling seamless integration with other tools and powerful migration paths that lead to world domination.
<br >

**Hot File Publishing:** Surgically `publish` or `unpublish` individual key-value pairs to and from external configuration files with a sassy flip of your hair.
<br >

**Atomic Counters:** Toss `increment` and `decrement` numerical values at the databeez to keep it guessing.
<br >

**Automated Installation & Safety:** A smart installer that configures your shell environment, plus automatic daily backups to protect your ~~doodles~~ data.
<br >

**Clean CLI Interface:** All SQL complexity is abstracted away into simple, intuitive commands like `getv`, `setv`, and `find`.


<br >



## 🚀 60-Second Quick Start

Forget the manual! 

Let's do something useful *right now*. Quick and easy setup then, we'll store a test API key for a new project called `webapp`.


```bash

# 1. Get the project repo. Duh. 
git clone https://github.com/qodeninja/bookdb.git
cd bookdb

# 2. Run the interactive interactor. You're a lizard Larry!
./bookdb install

# After installation you dont need the ./ invoker anymore!

# 3. First, see where we are. This is our 'before' picture.
bookdb status
#> --- BookDB Status ---
#>   ...
#>   Active Cursor: @GLOBAL.VAR.MAIN
#>   ...

# 4. Create a new project namespace for our webapp.
bookdb new project --ns webapp

# 5. Now for the magic. Create a 'config' keystore AND set our first key
#    in a single command using a "Context Chain".
#    This also sets our active cursor for next time!
bookdb setv API_KEY="key-super-secret-12345" @webapp.VAR.config
#> LOG: Persisting new context to cursor: webapp.config
#> LOG: Creating new variable: 'API_KEY'

# 6. Our cursor is now set. We don't need the full context chain anymore.
#    Let's get our key back.
bookdb getv API_KEY
#> key-super-secret-12345

# 7. Use it in a script! This is the whole point.
api_key=$(bookdb getv API_KEY)
echo "The API key for our awesome webapp is: ${api_key}"
#> The API key for our awesome webapp is: key-super-secret-12345

# There's much more power to this than just simple keystores!
#
```

And that's it. In less than a minute, you've created a namespaced, persistent variable and used it in a script. Now, let's understand the magic trick you just performed.



# VAR Keystore Concepts

## 💫 Context Chains & Cursors

The most powerful and unique features of `bookdb` is the **Context Chain** and the **Cursor File**. They provide the secret sauce that elevates bookdb from a simple key-value store to a true state management tool.

A **Context Chain** (chain) is a dot delimited string that gives commands a temporary or permanent "address" or "cursor" to work from. A fully qualified chain includes all relevant contexts with no assumed/implied contexts.

> A reasonable mental model is to think of a Context Chain as a package namespace, except with read and write permissions. 

> Note that all VAR commands use the `.VAR.` feature namespace as part of their sub chain:

```bash
     @.wepabb.VAR.config  #an example context chain with activation behavior
    \___________________/
```
> Context Chain Breakdown

```

  @       webapp      .VAR.      config
  |          |           |          |
PREFIX    PROJECT     KEYWORD    KEYSTORE
(The       (The top-   (For the    (The sub-folder
Action)    level        MVP, this    for your
           project)     is always    variables)
                        'VAR')
```


## Shape of a Context Chain

Generally, a *namespace*, is a placeholder for a value. Namespaces can be dot-linked together to form a chain (e.g. context chain). A namespace's position in a chain gives it a meta-context with special meaning. For example, the first and last namespaces in a context chain represent a behavior prefix, and lookup key respectively. 

The chain shape is misleading as the implied structure here is actually a tree; it has a trunk and can have multiple branches. 
The chain represents the path of nodes along the tree that define the heirarchal context we want to activate or access.

> In essence the Workspace = is the set of active heirachal contexts that create a Context Chain. A Context Chain is *activated* by applying it to a command with a write context.


```   
|       @ or %        |   |       context1      | |         VAR         |   |       context2      |
| -------- | -------- |   |  ------- | -------- | | -------- | -------- |   |  ------- | -------- |
|       PREFIX        |   |       PROJECT       | |      FEATURE NS     |   |       KEYSTORE      | 
 \___________________/  .  \___________________/ . \___________________/  .  \___________________/ ...

```


> The MVP implementation of VAR only supports a single level keystore, which means you cannot nest keystores. This may change in the future.

An **activated chain**  defines a session or workspace relative to its namespace heirarchy. When a chain is activated, a **workspace** is created via a stateful *Cursor File* (cursor). It houses the cached values of each individual namespace and represents an anchor for all subsequent commands within the session.

The cursor essentially solves the problem of having to include `--projdb webapp --keydb config` in every command, and opens up cleaner cli patterns for scripts and automation.

This is accomplished through the bookmarking power of the cursor. It indexes a marker for each active namespace in a chain. When the cursor is loaded by `bookdb`, it provides the workspace context for subsequence commands until a new workspace is started. 

> e.g. activating a chain = starting a session/workspace


### 🔗 Chain Behaviors
Chains currently offer two types of behavior modes `@ activate ` and `% readonly` via its PREFIX namespace. All chains must include an explicit behavior mode prefix when invoked, as there is no default.
<br>
<br> 
* **Activate/Write**

  Let's dissect the chain we used in the Quick Start: `@webapp.VAR.config`

  The magic lies in the **Prefix**. It tells `bookdb` *how* to treat the context for the command.

  #### `@` — The "Sticky" Cursor (Set & Execute)

  *   **What it does:** Uses the context for the current command **AND** saves it as the new default cursor for all future commands.
  *   **Analogy:** Think of `@` as `cd`-ing into a directory and *staying there*.
  *   **When to use it:** Use this when you are starting a new task and want all your subsequent `getv`, `setv`, `ls` commands to operate within that new context. This is what you'll use 90% of the time.

  ```bash
  # Set the cursor to @webapp.VAR.config
  bookdb status @webapp.VAR.config

  # This ls command now implicitly runs inside 'webapp.config'
  bookdb ls
  ```

* **Safe Invovation**

  The safe pattern is to set the cursor for every invocation, this prevents accidentally clobbering of precious keystore values by requiring a user to explicitly request the location they want to set for the cursor. It's important to point out that the indexing feature of the cursor is entirely optional, as you can prefer to explicitly call the context you want for each request.

  **Disable Auto Context (TBD)**
  In later versions, `bookdb` will support disabling the auto-loading of the cursor via an opt-in `DISABLE_CURSOR`. If you prefer explicit calls over magic calls.
<br>
<br> 
* **Readonly**

  Alternatively, the readonly mode runs an explicit command with an explicit chain and does not alter the underlying cursor. It's useful if you need to quickly crossover to another profile/project for commands but dont want to change the cursor. It's mostly a convenience command for power users, since using readonly mode can make it difficult to reason about the state of your keystore.

  #### `%` — The "Read-Only" Cursor (Execute Only)

  *   **What it does:** Uses the context **for this one command ONLY**. It does *not* change your active cursor.
  *   **Analogy:** Think of `%` as taking a quick peek into another directory for one task, without actually changing your current directory.
  *   **When to use it:** Perfect for when you're in the middle of working on one project but need to quickly grab a secret or a value from another, without losing your place.

  ```bash
  # You are currently working in @webapp.VAR.config
  bookdb cursor
  #> Active Cursor: @webapp.VAR.config

  # Quickly get the database password from the GLOBAL secrets keystore
  # without changing your cursor.
  DB_PASS=$(bookdb getv ADMIN_PASSWORD %GLOBAL.VAR.secrets)

  # You are still in your original context.
  bookdb cursor
  #> Active Cursor: @webapp.VAR.config
  ```
<br>
<br> 

### 🔗 The Final Form: Chains with Keys (`pub`/`unpub`)

The `pub` and `unpub` commands use an extended version of the chain that includes the key itself, allowing them to target a single variable for file operations.

`@<Project>.<VAR>.<Keystore>.<Key>`

This special form tells `pub` exactly which variable to find in the database and write to a file.

**The Golden Rule:** If you want to change your working context for the foreseeable future, use `@`. If you just need to grab one thing from somewhere else without losing your place, use `%`.




## 💫 Cursor Behavior

### Cursor Defaults
If no cursor is set, or any part of a fully qualified chain is missing, `bookdb` will automatically reset each missing context to their default. The top-level project or profile namespace uses a default `GLOBAL` context, whereas children namespaces default to `main`. 

This means after any reset or first install the default chain (also known as the **Super Global Context Chain** ) is always available as `@GLOBAL.VAR.main`. 


### Super Global Context Chain (super chain)

The super chain is special in that it is the only context that offers inheritance (currently) to child chains when exported. This means that when any keystore in the `GLOBAL.VAR.*` namespace is published to a file, it will also include all the keys from `@GLOBAL.VAR.main` first. This feature may be expanded out to top-level project keys in later versions.

You can get your super chain, via the `super` shortcut.

```bash
    bookdb super; #returns @GLOBAL.VAR.main
    bookdb super ls; #list all keytores of the super chain
```
**Cascading**
While the super chain is standard to VAR, its cascading behavior is opt-in and guarded by a global variable `SUPER_CASCADING`.


###  Changing the Workspace Cursor 

By default the active chain can be changed alongside any command as an argument; `bookdb` will respect the request as first-class behavior. You can also set the cursor silently using the `noop` (no-operation) command.

```bash
  
  bookdb cursor; #get the current workspace
  
  bookdb noop @GLOBAL.VAR.COLOR; #change the workspace to the GLOBAL keytore of COLOR
  bookdb setv FAVORITE_COLOR="red"; #<-- no chain arg, using cached workspace

```



## Advanced Usage


### Advanced Exporting and Importing 

**Exporting**

```bash
  # Export all keystores from the 'GLOBAL' project only:
  for ks in $(bookdb ls vars @GLOBAL.VAR.MAIN); do
    bookdb export keystore @GLOBAL.VAR.$ks #automagically creates global_[ks].env
  done
```

**Importing**

```bash
  # Import these keys back to the databeez! Call them cool and make them global
  bookdb import global_coolkeys.env
```

**Migrate**



```bash
  # Start with the migrate cmd to create your full bookdb backup directory
  # usually called bookdb_fullback_NNNN/ zip it if you must!
  # Doll up the ducks darling we're driving to Denver.
  bookdb migrate
```
**Restore/Slurp**

Some advanced behaviors enabled by `bookdb` can be achieved by using composable/pipeable tools. For example, a mass restore function to slurp up a directory of env files into your keystores is easily done with grep, a for-loop, and an opposable thumb.

```bash
  # Restore previous bookdb state using backup files from a migrated folder.
  # Why do we have so many ducks?? 
  for file in bookdb_fullbak_*/; do bookdb import "\$file" -y; done
```

You already have all the power, you do not need more power! Is there more? Why yes!

----

### 🔥 Hot File Publishing (`pub`/`unpub`)

Aka the "why is my hair on fire?" Tool.

While `export` is great for dumping an entire keystore, `pub` and `unpub` are designed for managing individual lines in a configuration file (like `.env`). This keeps your configs perfectly in sync with `bookdb` as your single source of truth.

This is super advance dark magic of `sed`, there is no coming back from the doom you unleash using this power. Thank goodness for `SAFE_MODE` amiright? Well consider this DANGER_ZONE_MODE. 

⚠️ Safe mode does not *yet* apply to hot file context-chain publishing, but such a change *can* be rewounded __unless__ you clobbered a pre-existing variable! You *can* backup your own files before, eh, tinkering. Do not bring down the entirety of Cloudflare with this dark magic. (*Jots notes, adds to roadmap*)

>  BONUS EXCLUSIVE FOR CLOUDFLARE EMPLOYEES: This command comes with a FREE, invisible ghost that will follow you around and ask, 'Are you sure you meant to edit that production config?'

Great power, great responsibility. 

Behold the runes of yore:


```bash
# First, store a port number in bookdb
bookdb setv PORT=8080 @webapp.VAR.config

# Now, publish that specific key to your application's .env file.
# The context chain now includes the key itself.
bookdb pub @webapp.VAR.config.PORT ./webapp.env

# The file webapp.env now contains the line:
# PORT=8080

# Later, you decide to change the port. You only need to update bookdb.
bookdb setv PORT=9000 @webapp.VAR.config

# Re-run the same publish command to update the file.
bookdb pub @webapp.VAR.config.PORT ./webapp.env

# The file webapp.env is now intelligently updated to:
# PORT=9000

# To remove the key from the config file:
bookdb unpub @webapp.VAR.config.PORT ./webapp.env
```

> A wild Dev Ops appears.

> Book used pub, it was very effective.

----

## 🤖 Scripting & Automation (Modes)

You can alter `bookdb`'s default behavior using environment variables, which is perfect for CI/CD pipelines or automated scripts. Set DEV_MODE or SAFE_MODE in your environment or by setting it ahead of the script call:

*   `DEV_MODE=true`: Bypasses all confirmation prompts (`[y/N]`). Equivalent to using the `-y` flag for every command.
    ```bash
    # This will completely reset the installation without asking for confirmation.
    DEV_MODE=true bookdb reset; #front loaded variable 
    ```
*   `SAFE_MODE=true`: Enables automatic daily backups (one backup per day per invocation on that day to be precise). Before the first destructive action of the day (like `del`, `reset`), `bookdb` will create a timestamped backup of the database file in `~/.local/share/bookdb/backups/`. 
    ```bash
    # This ensures a backup is made before the deletion occurs.
    SAFE_MODE=true bookdb delv CRITICAL_KEY; #front loaded variable 
    ```



## 🪜Installation
 
 Instatllation is so easy it almost doesn't need instructions, but we'll spell out the steps for completeness.


### 🤔Requirements

`bookdb` features a friendly, interactive installer that handles everything for you... *except* your sqlite3 installation and how you might feel about that.

#### Prerequisite: Install `sqlite3`

You should have `sqlite3` installed and available in your `PATH`. You can check this by running `command -v sqlite3`. If you've never used it before, dont worry it's *pretty* lighweight and defacto on many systems.  

If it's not found, here's how to install it on common systems:

*   **On Debian/Ubuntu:**
    ```bash
    sudo apt-get update && sudo apt-get install sqlite3
    ```
*   **On Red Hat/CentOS/Fedora:**
    ```bash
    sudo yum install sqlite
    # Or, on modern Fedora:
    sudo dnf install sqlite3
    ```
*   **On macOS (with Homebrew):**
    ```bash
    brew install sqlite
    ```


### 📦BookDB Easy Install

**1. Get the Repo.**

Generally, `bookdb` is such a flirt that it'll try to install itself whenever it detects an anomoly in its reality anchors (dont worry, wont clobber); barring that you can install as follows:


```bash
# 1. Get the project repo. Duh. You cant databeez stuff without it. unless your a wizard.
git clone https://github.com/qodeninja/bookdb.git
cd bookdb

# 2. Run the interactive interactor. You're a lizard Larry!
./bookdb install
```

**2. What that button do?**

The installer will:
1.  Explain the actions it will take (creating directories, copying the script to `~/.local/bin/`, etc.).
2.  Intelligently detect your shell profile (`~/.bashrc`, `.profile`, ~~`~/.zshrc`~~, etc.). 
3.  Ask for your confirmation before making any changes.

Once you grudginly approve the injection of a powerful alien tool into your unsuspecting system, it will automatically configure your ~~soul~~ shell. Adventure seekers among us can alternatively avoid all the fluff and fatigue with a well placed `-y` flag.


**3. Restart Your ~~Soul~~ Shell**

To complete the ~~assimilation~~ installation, start a new shell session or run `source ~/.bashrc` (or your appropriate profile file). The `bookdb` command will now be available everywhere.

👁️ Note: once you've installed `bookdb` into your system  you wont have to use the `./` invoker anymore.
```bash
# Call me anytime, im here on the ... line. Commmand line.
bookdb status

# list all of my horcruxes.
bookdb ls
```

Ok, that was the EZ PZ PART, as promised. Next comes the crazy stuff.



<br>

## ☠️ Uninstallation

### One liner.

`bookdb` is designed to be ~~fully~~ mostly rewindable. The `reset` command acts as a complete uninstaller. Easy peezy :

```bash
# Undo the did, and send bookdb off to oblivion.
bookdb reset; # -y if youre funky
```
After confirmation or a `-y` skip, it will:
*   Delete itself from `~/.local/bin/`. 
*   Delete all databases, configuration, and state files.
*   Clean up the `source` line from your shell profile.

Your system will be left in ~~the exact~~ a similar state as it was before `bookdb` was installed.

### Your User Data 

If you'd like to keep the data from your keystores for later use, you can use the backup utility to create a zip of all your bookdb-related data. Eh, be sure to do this before you nuke.
* `bookdb backup` 
* not to be confused with `bookdb migrate` which only backs up your transferable keystores. (*jots notes in roadmap section... hides notes*)

### The Final, Final Step

Stroy time: so, whenever your shell learns a new script it adds it to an internal cache and counts how many time you use it. Neat! However, when "uninstalling" a script via good ol' rimraf, the shell plays dumb and acts like it doesnt know what happened.

So in our case, if you try to run `bookdb` again, it will complain it doesnt exist... well duh, I deleted it. Right? Wrong.

You need to delete it from `hash`. And yes, `bookdb` would love to do this for your but it's ~~impossible~~ unfeasable. 

First, check the high scores by running `hash`.

Next, nuke the duke. You can do this one of two ways:

1. Clear the whole hash `hash -r`

2. Clear the specific hash `hash -d bookdb`


The clearing the ~hole~ whole is more effective if the ~~ladder~~ latter ever fails. This mostly applies if youre like me and strongly dislike restarting your finely handcrafted meatball flavored shell session.🤌

And there you have it folks, *BashFX-compliant* full Rewind! *mic drop* 🎤


## 🫡 Command Reference

Gotta now the commands if you want to be a commander, sergeant. BTW, these all do great things you should learn cause wow. I dunno why I made this so cool. Look how cool it is! 

### 💖 Sup? Commands

| Command           | Description                                             | Example                                    |
| ----------------- | ------------------------------------------------------- | ------------------------------------------ |
| `status`          | Display a dashboard of the system's state and projects. | `bookdb status`                            |
| `cursor`          | Print the current active cursor chain.                  | `bookdb cursor`                            |
| `find <PATTERN>`  | Find a key across all namespaces using SQL `LIKE`.        | `bookdb find '%API_KEY%'`                  |

### ✨ Variable Management

| Command                 | Description                                                  | Example                                         |
| ----------------------- | ------------------------------------------------------------ | ----------------------------------------------- |
| `getv <KEY>`            | Get the value of a variable.                                 | `api_key=$(bookdb getv API_KEY)`                |
| `setv <KEY=VALUE>`      | Create or update a variable.                                 | `bookdb setv USER="alex"`                         |
| `delv <KEY>`            | Delete a variable.                                           | `bookdb delv OLD_TOKEN`                         |
| `incv <KEY> [amount]`   | Increment a numerical value (default: 1).                    | `bookdb incv LOGIN_COUNT`                         |
| `decv <KEY> [amount]`   | Decrement a numerical value (default: 1).                    | `bookdb decv REMAINING_ATTEMPTS 2`                |
| `ls`                    | List all variables in the current key-value namespace.       | `bookdb ls`                                     |
| `pub <@chain.key> <file>`| Publish (write/update) a single key-value to a file.      | `bookdb pub @app.VAR.cfg.PORT .env`           |
| `unpub <@chain.key> <file>`| Unpublish (remove) a key from a file.                    | `bookdb unpub @app.VAR.cfg.OLD_KEY .env`        |

### 🔖 Namespace Management

| Command                       | Description                                                     | Example                                      |
| ----------------------------- | --------------------------------------------------------------- | -------------------------------------------- |
| `new project --ns <name>`     | Create a new top-level project.                                 | `bookdb new project --ns my-cli-tool`        |
| `new keyval --ns <name>`      | Create a new key-value store within the current project.        | `bookdb new keyval --ns user_prefs`          |
| `del project --ns <name>`     | **Permanently delete a project and all its contents.**          | `bookdb del project --ns old-project`        |
| `del keyval --ns <name>`      | **Permanently delete a key-value store and all its variables.** | `bookdb del keyval --ns cache`               |
| `ls project`                  | List all available projects.                                    | `bookdb ls project`                          |
| `ls vars`                     | List all key-value stores within the current project.           | `bookdb ls vars`                             |

### 👑 Admin, I/O, and Dev Commands

| Command                 | Description                                                              | Example                                      |
| ----------------------- | ------------------------------------------------------------------------ | -------------------------------------------- |
| `install`               | Safely create or verify the `bookdb` installation.                       | `bookdb install`                             |
| `reset [-y]`            | **DELETE ALL DATA** and reset `bookdb` to a clean state.                   | `bookdb reset --yes`                         |
| `backup`                | Create a manual, full backup in your home directory.                     | `bookdb backup`                              |
| `export keystore`       | Export the current keystore to a `PNS_KVNS.env` file.                    | `bookdb export keystore`                     |
| `import <file.env>`     | Import keys from a `.env` file into a context.                           | `bookdb import my_app.env`                   |
| `migrate`               | Export *all* keystores from the database into a backup directory.        | `bookdb migrate`                             |
| `dev_setup`             | Reset and seed the database with a standard set of test data.            | `bookdb dev_setup`                           |
<br>


## ⚡BashFX Principles 
On a more 9-to-5 note, `bookdb` is built according to a set principles called **BashFX**, designed to make shell tools powerful without being rude. 

For you as a user, this means:

*   **Self-Contained:** All installation artifacts (the database, config files, etc.) live inside a single standardized root directory: `~/.local`.
*   **Invisible:** `bookdb` will never create new dotfiles (`.bookdb`, etc.) in your `$HOME` directory or  pollute your home with anything it generates. It keeps its mess in its own room.
*   **Rewindable:** The automated `install` has an equally automated counterpart. The `reset` command will fully uninstall `bookdb`, removing the script, all data, and its entry from your shell profile. *Most* commands have a rewindable counterpart.
*   **Friendly:** The tool should be proactive in communicating its state. Commands like `status` and `cursor`, and the use of clear log messages, are designed to keep you informed.


## ⁉️🤔 Frequently Asked Questions
Or what I like to call, "an interpretive dance of mimes in text-only format."

* Q: **Why is this called BookDB if there are no books involved?**<br>
⮧ A: Anything can be a book if you try hard enough.

* Q: **What are databeez?**<br>
⮧ A: They are the beez that feed on your keyz. Dur! Feed them keys. Watch em cheez!

* Q: **Why do you hate Cloudflare?**<br>
⮧ A: I don't, yet. They're welcome to send me flowers for no reason. Bzzz.

* Q: **Why did you make BookDB?**<br>
⮧ A: Beaver + Spandex. See opening synopsis.

* Q: **You blew up my system! do you care?**<br>
⮧ A: I did once.

* Q: **What is BashFX?**<br>
⮧ A: Willy Wonka meets command line scripting, only less self-actualizing.

* Q: **Why cant you just follow the everybody standards?**<br>
⮧ A: I am the standard creator.

* Q: **Why is this README so dumb?**<br>
⮧ A: I dunno but the probablity parser gave me five stars. Probably got lost in the paradox. tsk tsk


* Q: **Question for you reader. Did you read this whole thing?**<br>
⮧ A: If you did, then know this tool I made for me, is a gift to you.

## 🤔 Why Use This?

* Cool people use this, like me. 
* You dislike all things SQL but appreciate well-meaning abstractions.
* You realize the power of regex, but your philonthropic leanings leave room for others to bang their head on the keyboard in your stead. 
* There's some wild to your child, but need more power in your flower.
* You have environs, and they need some mints. Managemints!
* You wanna see what this baby can do! *slaps the hood*

DO NOT USE THIS IF:

* You are not cool aka use zsh.
* You take metaphors literally.
* Have no idea what you're doing (cuz I dont either.)
* Are an employee at Cloudflare. JK! but dont use it in production. *side eye*

## ⚠️ Beta Version

  Generally, Debian-based distros with Bash 3.2+ or higher are supported, since direct manual tests of each MVP phase passed without errors, e.g. "works on my machine."
  
  Hypothetically any Bash 3.2+ environment might be compatible; except where certain command idioms differ by OS or implementation. `sed` is a usual suspect among others. 

  **Help Us Cure Works-On-My-Machine Syndrome** and bring wider support to more folks by testing it on your system(s). 

  As a self-contained script `bookdb` wont evil-mangle your stuff, so if you're willing to give er a go, and see what blows in an effort to determine cross-system support, that contribution is most welcome!

  **Assume every new untested tool may cause unforeseen issues, and make sure your data/system state is recoverable before using!**

  Having said that, if you accept these risks and limitations, we get the deeds did and the databeez ~~fid~~ fed.



## Testing / Compatibility


  * `bookdb` passed **Phase I II III IV V** manual testing suites on a Debian-based distro. This is basically saying nothing of value to a zero-context reader. You might guess.
  
  * It is 95% **MVP-Compliant** with the BashFX Architecture v1.6. Meaning it works on my computer, but YMMV. 

  * Further testing is needed to ensure wider portability. Certain idioms like `sed` or `grep` may have OS-specific alternatives that arent currently used by bookdb.

## Roadmap / Todo

  * Probably Urgent
    * DANGER_ZONE_MODE fixes. Safety goggles for the kittens.
    * Ponder why or whether `migrate` supports transfering support files.
    * Ponder why `backup` functionally different than `migrate`.

  * Planned integration with the BashFX Framework.
    * Implement BashFX Standard Interface. 
    * Base refactor using BashFX `bootstrap` library.
    * Standard refactor using BashFX `stderr` library.
    * Compatibility refactor using BashFX `portable` library.
    * Options refactor using BashFX `stdopts` library.
    * Clean up manually integrated libraries.
    * Support BashFX `use_app` idiom. 

  * Additional Features.
    * Support read-only context-chains.
    * Support `SUPER_CASCADING` to enable inheritance of super chain on export.
    * Support `DISABLE_CURSOR` to require explicit chain invocation on all calls.
    * Support notes/journal namespace via the JRNL context-chain.
    * Support features/task namespace via the TASK context-chain.
    * Support bookmarks (integration with `markman` tool) via MARK context-chain.

  * Considerations.
    * Zsh support.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
