# claude-tools Quick Reference

## Essential Commands

### List conversations
```bash
claude-ls                    # Current directory
claude-ls ~/project         # Specific directory
claude-ls ~/dev/*           # Multiple directories
claude-ls --complete        # Show all available projects
```

### Copy conversations (fork with new UUID)
```bash
claude-cp ~/src ~/dest      # Copy most recent
claude-cp ~/src ~/dest abc  # Copy specific (prefix match)
claude-cp ~/src ~/dest --   # List available conversations
```

### Move conversations (keep UUID)
```bash
claude-mv ~/src ~/dest      # Move most recent
claude-mv ~/src ~/dest abc  # Move specific
claude-mv ~/src ~/dest -    # Move most recent (explicit)
```

### Remove conversations
```bash
claude-rm ~/project abc     # Remove specific
claude-rm ~/project -       # Remove most recent
```

### Clean up old projects
```bash
claude-clean                # Preview cleanup (safe)
claude-clean --execute      # Actually clean
claude-clean --days=60      # Custom age threshold
```

## Git Worktree Workflow

```bash
# Save context before deleting worktree
gwt done
claude-cp . ~/archive/feature-xyz

# Restore context in new worktree
gwt new bugfix
claude-cp ../feature-xyz .  # Works even if deleted!
```

## Ghost Directories

```bash
# Find all ghost directories
claude-cp --complete-source | grep "(ghost)"

# List from deleted directory
claude-ls ~/deleted-project

# Copy from ghost
claude-cp ~/deleted-project ~/new-project
```

## Pipes and Automation

```bash
# Interactive selection with fzf
claude-cp ~/src ~/dest -- | fzf | cut -f1 | xargs claude-cp ~/src ~/dest

# Backup all projects
for dir in ~/dev/*; do
  claude-cp "$dir" ~/backup/$(date +%Y%m%d)
done

# Find and copy specific conversation
claude-ls ~/project | grep "auth" | cut -f2 | xargs claude-cp ~/project ~/dest
```

## Flags

| Flag | Tools | Purpose |
|------|-------|---------|
| `--dry-run` | cp | Preview without action |
| `--verbose` | cp, clean | Detailed output |
| `--exec` | cp | Launch Claude after |
| `--execute` | clean | Actually perform cleanup |
| `--empty-only` | clean | Only target empty dirs |
| `--days=N` | clean | Set staleness threshold |
| `--complete` | ls | List all projects |
| `--complete-source` | cp | List sources for completion |

## File Locations

- Conversations: `~/.claude/projects/[encoded-path]/*.jsonl`
- Completions: `completions/claude-tools.{bash,zsh}`
- Binaries: `_build/default/bin/claude_*.exe`

## UUID Behavior

| Operation | UUID Handling |
|-----------|--------------|
| `claude-cp` | Generates NEW UUID (fork) |
| `claude-mv` | Preserves SAME UUID (move) |
| `claude-rm` | Deletes conversation |

## Exit Codes

- `0` - Success
- `1` - Error (conversation not found, etc.)
- `2` - Invalid arguments

## Metadata Format

```json
{
  "type": "metadata",
  "tool": "claude-cp",
  "action": "copy",
  "timestamp": "2025-10-22T12:34:56Z",
  "source_path": "/src",
  "dest_path": "/dest",
  "source_id": "original-uuid",
  "version": "1.0.0"
}
```