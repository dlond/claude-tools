# claude-tools

A suite of Unix-style utilities for managing [Claude Code](https://claude.com/claude-code) conversations, implementing a Claude Virtual Filesystem (CVF) abstraction.

## Overview

This project treats Claude conversations as a virtual filesystem, providing familiar Unix-like commands for managing your AI conversations. All tools support "ghost directories" - directories that have been deleted but still have conversations stored.

## Available Tools

| Tool | Purpose | Status |
|------|---------|--------|
| `claude-ls` | List conversations | ✅ Complete |
| `claude-cp` | Copy conversations (creates forks) | ✅ Complete |
| `claude-mv` | Move conversations (preserves UUID) | ✅ Complete |
| `claude-rm` | Remove conversations | ✅ Complete |
| `claude-clean` | Clean up orphaned projects | ✅ Complete |
| `claude-search` | Search across conversations | 📋 Planned |

## Installation

### Quick Install with Nix

```bash
# Install directly from GitHub (recommended for users)
nix profile install github:dlond/claude-tools

# Or run without installing
nix run github:dlond/claude-tools -- --help
```

### Install from Source

#### Using Nix (for developers)

```bash
# Clone and build
git clone https://github.com/dlond/claude-tools.git
cd claude-tools

# Build the package
nix build

# Install to your profile
nix profile install .

# Or enter development shell for hacking
nix develop
dune build
```

#### Using opam

```bash
# Install dependencies
opam install dune yojson uuidm cmdliner

# Build
dune build

# Install
dune install --prefix ~/.local
```

### Shell Completions

Shell completions are automatically installed when using Nix. For manual installation:

```bash
# Bash - add to ~/.bashrc
source /path/to/claude-tools/completions/claude-tools.bash

# Zsh - add to ~/.zshrc
source /path/to/claude-tools/completions/claude-tools.zsh
```

## Tool Documentation

### claude-ls

List conversations in one or more projects with timestamps and summaries.

```bash
# List conversations in current directory
claude-ls

# List from specific directory
claude-ls ~/dev/project

# List from multiple directories
claude-ls ~/proj1 ~/proj2

# Use glob patterns
claude-ls ~/dev/worktrees/*

# List all available projects (for tab completion)
claude-ls --complete
```

**Features:**
- Shows conversation ID, timestamp, and summary
- Supports multiple directories and glob patterns
- Works with ghost directories (deleted but with stored conversations)
- Sorted by most recent first

### claude-cp

Copy conversations between projects, creating a new fork with a unique UUID.

```bash
# Copy most recent conversation
claude-cp ~/old-project ~/new-project

# Copy specific conversation by ID or prefix
claude-cp ~/old-project ~/new-project abc123

# List available conversations
claude-cp ~/old-project ~/new-project --

# Interactive selection with pipe
claude-cp ~/source ~/dest -- | fzf | cut -f1 | xargs claude-cp ~/source ~/dest

# Flags
claude-cp ~/source ~/dest --dry-run    # Preview without copying
claude-cp ~/source ~/dest --verbose    # Detailed output
claude-cp ~/source ~/dest --exec       # Launch Claude after copying
```

**Features:**
- Generates new UUID for each copy (creates independent fork)
- Updates all sessionId fields to match new UUID
- Adds metadata logging for audit trail
- Tracks lineage via parentUuid field
- Supports ghost directories as source

**Piping examples:**
```bash
# Copy from ghost directory after deleting worktree
gwt done
claude-cp ../deleted-worktree ~/new-project

# Copy most recent from each project to archive
for proj in ~/dev/*; do
  claude-cp "$proj" ~/archive/$(date +%Y%m%d)
done
```

### claude-mv

Move conversations between projects, preserving the original UUID.

```bash
# Move most recent conversation
claude-mv ~/old-project ~/new-project

# Move specific conversation
claude-mv ~/old-project ~/new-project abc123

# Move with explicit "most recent"
claude-mv ~/old-project ~/new-project -
```

**Features:**
- Preserves original UUID (true move, not copy)
- Adds metadata logging for move operation
- Atomic operation using rename
- Checks for existing conversation in destination

### claude-rm

Remove conversations from projects.

```bash
# Remove specific conversation
claude-rm ~/project abc123

# Remove most recent conversation
claude-rm ~/project -

# Remove by prefix
claude-rm ~/project abc  # Removes abc123-full-uuid if unique
```

### claude-clean

Clean up empty or stale project directories to reclaim disk space.

```bash
# Dry run (default - safe!)
claude-clean

# Actually remove orphaned projects
claude-clean --execute

# Only show/remove empty directories
claude-clean --empty-only

# Custom staleness threshold (default 30 days)
claude-clean --days=60

# Verbose output
claude-clean --verbose
```

**Features:**
- Safe by default (requires --execute to actually remove)
- Shows disk space to be reclaimed
- Identifies empty projects and stale projects
- Configurable age threshold

**Example output:**
```
Would remove 5 projects:

Empty projects (2):
  /tmp/test-project (ghost) (45 days ago)
  /tmp/old-experiment (62 days ago)

Stale projects (3):
  /Users/you/deleted-repo (ghost) (3 conversations, 92 days ago)
  /tmp/abandoned-test (1 conversation, 47 days ago)

Total space to reclaim: 2.3 MB

Run with --execute to actually remove these projects.
```

## Ghost Directories

A unique feature of claude-tools is support for "ghost directories" - directories that no longer exist but still have conversations stored in `~/.claude/projects/`. This is perfect for git worktree workflows:

```bash
# Create worktree and work on feature
gwt new feature-xyz
cd ~/dev/worktrees/project/feature-xyz
# ... work with Claude ...

# Delete worktree but conversations remain
gwt done

# Later, in a new worktree, copy from the ghost
gwt new another-feature
claude-cp ../feature-xyz .  # Works even though directory is gone!
```

Tab completion will show ghost directories marked with "(ghost)":
```bash
$ claude-cp <TAB>
../feature-xyz     (ghost) 3 conversations, last: 2 hours ago
~/dev/project      17 conversations, last: today
```

## Metadata Logging

All mutation operations (cp, mv) append metadata to conversation files:

```json
{
  "type": "metadata",
  "tool": "claude-cp",
  "action": "copy",
  "timestamp": "2025-10-22T12:34:56Z",
  "source_path": "/original/path",
  "dest_path": "/new/path",
  "source_id": "original-uuid",
  "version": "1.0.0"
}
```

This provides a complete audit trail and lineage tracking for conversations.

## Git Workflow Integration

Example git aliases for your `.gitconfig`:

```bash
[alias]
    # Create worktree and copy most recent Claude conversation
    wt-new = "!f() { \
        git worktree add ~/dev/worktrees/$(basename $(pwd))/$1 -b $1 && \
        claude-cp . ~/dev/worktrees/$(basename $(pwd))/$1 && \
        cd ~/dev/worktrees/$(basename $(pwd))/$1; \
    }; f"

    # Archive conversations before removing worktree
    wt-done = "!f() { \
        claude-cp . ~/claude-archive/$(date +%Y%m%d)-$1; \
        git worktree remove .; \
    }; f"
```

## Common Workflows

### Continuing work in a new worktree
```bash
# Finish feature branch
gwt done

# Start new branch with context
gwt new bugfix
claude-cp ../feature-branch .
```

### Backing up conversations
```bash
# Backup all projects to archive
for dir in ~/dev/projects/*; do
  claude-cp "$dir" ~/backups/$(date +%Y%m%d)/$(basename "$dir") 2>/dev/null
done
```

### Finding old conversations
```bash
# List all ghost directories
claude-cp --complete-source | grep "(ghost)"

# Search for specific project
claude-ls ~/dev/old-project-*
```

### Cleaning up disk space
```bash
# See what can be cleaned
claude-clean

# Remove only empty projects
claude-clean --empty-only --execute

# Remove everything older than 90 days
claude-clean --days=90 --execute
```

## Architecture

claude-tools implements a Claude Virtual Filesystem (CVF) abstraction layer that:

1. **Path Resolution**: Maps filesystem paths to Claude's internal storage format
2. **Ghost Discovery**: Finds conversations from deleted directories
3. **Metadata Tracking**: Maintains audit trail for all operations
4. **UUID Management**: Handles conversation identity (fork vs move)

Conversations are stored in `~/.claude/projects/` with paths encoded as:
- `/Users/alice/dev/project` → `~/.claude/projects/-Users-alice-dev-project/`
- `/tmp/test` → `~/.claude/projects/-private-tmp-test/` (on macOS with symlink resolution)

## Contributing

Issues and pull requests are welcome! See open issues for planned features.

### Development

```bash
# Run tests
dune test

# Build and test a specific tool
dune exec bin/claude_ls.exe ~/dev/project

# Format code
dune fmt
```

### Planned Features

- `claude-search` - Search across all conversations
- Color output support
- Export to markdown
- Conversation merging

## License

MIT