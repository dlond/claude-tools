# Shell Completions for claude-tools

Tab completion support for claude-tools commands, including ghost directory discovery.

## Features

- **Ghost directory completion**: Tab complete source directories that no longer exist but still have conversations
- **Smart argument awareness**: Source arguments show ghosts, destination arguments only show real directories
- **Conversation ID completion**: Tab complete conversation IDs when specifying which one to copy

## Installation

### Bash

Add to your `.bashrc` or `.bash_profile`:

```bash
source /path/to/claude-tools/completions/claude-tools.bash
```

### Zsh

Add to your `.zshrc`:

```zsh
source /path/to/claude-tools/completions/claude-tools.zsh
```

Or copy to your completions directory:

```bash
cp completions/claude-tools.zsh ~/.zsh/completions/_claude-tools
```

## Usage Examples

```bash
# Tab complete sources (includes ghost directories)
$ claude-ls <TAB>
/tmp/deleted-project     # Ghost directory
~/dev/projects/nvim      # Real directory

# Tab complete claude-cp source (includes ghosts)
$ claude-cp <TAB>
../old-worktree/         # Ghost from deleted worktree
~/dev/projects/app/      # Real project

# Tab complete destination (only real directories)
$ claude-cp ../old-worktree/ <TAB>
~/dev/new-project/
./current-dir/

# Tab complete conversation IDs
$ claude-cp ~/project ~/dest <TAB>
abc123-def456
789ghi-jkl012
--                      # List all conversations
```

## How It Works

1. The completion scripts call `claude-ls --complete` or `claude-cp --complete-source`
2. These commands scan `~/.claude/projects/*` and discover ghost directories
3. Ghost directories are marked with "(ghost)" but still tab-completable
4. The scripts are context-aware - only showing ghosts for source arguments