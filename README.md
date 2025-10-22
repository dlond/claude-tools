# claude-tools

A suite of Unix-style utilities for managing [Claude Code](https://claude.com/claude-code) conversations, implementing a Claude Virtual Filesystem (CVF) abstraction.

## Project Status

🚧 **Under active development** - Rewriting from Bash to OCaml for better performance and maintainability.

## Philosophy

This project treats Claude conversations as a virtual filesystem, enabling familiar Unix operations:
- `claude-ls` - List conversations (like `ls`)
- `claude-cp` - Copy conversations between projects (like `cp`)
- `claude-search` - Search across conversations (like `grep`) *(planned)*
- More tools following Unix philosophy...

## Available Tools

### claude-ls (OCaml) ✅

List Claude conversations for a project with summaries and timestamps.

```bash
$ claude-ls ~/dev/projects/nvim
2025-10-21 04:00  bbfdce7d  Neovim Config Codebase Exploration Warmup
2025-10-21 03:59  ad44dec8  (No summary)
2025-10-20 06:47  eee0bb61  Neovim Codebase Search Assistant Warmup
```

### claude-cp (Bash - being ported to OCaml)

Copy Claude Code conversations between projects. Perfect for resuming work in a different directory.

## Installation

### For Development (OCaml tools)

```bash
# Clone the repo
git clone https://github.com/dlond/claude-tools.git
cd claude-tools

# Using Nix (recommended)
nix develop
dune build

# Or using opam
opam install dune yojson cmdliner alcotest
dune build
```

### For Bash tools (temporary)

```bash
# Add to your PATH
export PATH="$PATH:$(pwd)/bash"

# Or copy individual tools
cp bash/claude-cp ~/bin/
chmod +x ~/bin/claude-cp
```

---

## claude-cp

### Usage

```bash
claude-cp <dest_dir> [source_dir]
```

Copy a conversation from `source_dir` (defaults to current directory) to `dest_dir`.

### Examples

```bash
# Copy a conversation from current directory to another project
claude-cp ~/projects/my-app

# Copy from a specific source to a destination
claude-cp ~/projects/new-feature ~/projects/old-feature

# Copy from a deleted worktree (directory doesn't need to exist!)
claude-cp ~/dev/new-project ~/dev/worktrees/deleted-branch
```

### Interactive Selection

If you have [fzf](https://github.com/junegunn/fzf) installed, you'll get an interactive picker with:
- Conversation summaries and previews
- Recent messages
- Scrollable preview (Ctrl-D/U)

Without fzf, you'll get a simple numbered menu.

### Options

```
-h, --help      Show help message
--dry-run       Show what would be done without doing it
--no-fzf        Use simple menu instead of fzf (useful for scripts)
```

### How it works

Claude Code stores conversations in `~/.claude/projects/[directory-path]/`. This script:

1. Lists all conversations from the source directory
2. Lets you pick one (with summaries!)
3. Copies it to the destination directory's project folder
4. Gives you the exact command to resume it

### Features

- 📋 **Smart summaries** - Shows conversation summaries, or falls back to first message
- 🕐 **Recent first** - Sorts by modification time
- 🔗 **Symlink aware** - Handles macOS `/tmp` → `/private/tmp` correctly
- 📁 **Auto-create** - Creates destination directory if needed
- 👻 **Ghost directories** - Works even if source directory is deleted
- 🎨 **Beautiful preview** - fzf integration with scrollable conversation preview

### Requirements

- `bash` 3.2+
- `jq` (for parsing conversation files)
- `fzf` (optional, for interactive picker)

### Example Session

```bash
$ claude-cp ~/new-project
Available conversations:

 1) Neovim Config: Comprehensive Keybinding Analysis
 2) Bug Fix: Authentication Flow
 3) Feature: Dark Mode Implementation

Select conversation (1-3): 1

Copied conversation to /Users/you/new-project

To resume:
  cd "/Users/you/new-project"
  claude --resume "a1b2c3d4-e5f6-7890-abcd-ef1234567890"
```

### Why?

Git worktrees are temporary. Context shouldn't be. Keep your conversations even after you delete the branch.

---

## Contributing

Got ideas for more Claude Code utilities? Found a bug? Contributions are welcome!

- **Issues**: Report bugs or request features
- **Pull Requests**: Add new tools or improve existing ones
- **Ideas**: Share your Claude Code workflow hacks

New tools should:
- Follow Unix philosophy (do one thing well)
- Include help text and examples
- Work on macOS and Linux
- Have clear, tested code

## License

MIT
