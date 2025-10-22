# Contributing to claude-tools

Thanks for contributing! This guide covers the basics of working on claude-tools.

## Quick Start

```bash
# Clone and set up
git clone https://github.com/dlond/claude-tools.git
cd claude-tools
nix develop      # Or: opam install dune yojson cmdliner uuidm

# Build and test
dune build       # Build all tools
dune test        # Run tests
dune fmt         # Format code
```

## Project Structure

```
bin/         # Tool executables (claude_ls.ml, etc.)
lib/         # Shared code (cvfs.ml)
test/        # Unit tests
completions/ # Shell completions
```

## Making Changes

### Adding a New Tool

1. Create `bin/claude_newtool.ml`
2. Add to `bin/dune`
3. Update shell completions
4. Add tests
5. Document in README.md

### Code Style

- Run `dune fmt` before committing
- Use meaningful variable names
- Handle errors explicitly
- Exit codes: 0 (success), 1 (error), 2 (usage)

### Testing

```bash
dune test                          # Run all tests
dune exec bin/claude_ls.exe -- .   # Test manually
```

## Submitting Changes

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Run `dune test` and `dune fmt`
5. Commit with clear message (e.g., `feat: add new feature`)
6. Open a Pull Request

## Questions?

Open an issue or discussion on GitHub. We're happy to help!