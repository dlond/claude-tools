{
  description = "OCaml development environment from dlond/system-flakes#ocaml";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    system-flakes = {
      url = "github:dlond/system-flakes";
      # For local development: url = "path:/Users/dlond/dev/projects/system-flakes";
    };
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    system-flakes,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # Import packages from system-flakes
      packages = import "${system-flakes}/lib/packages.nix" {
        inherit pkgs;
      };
    in {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs;
          [
            # OCaml compiler and build tools
            ocaml
            dune_3
            opam # For additional packages as needed

            # Jane Street essentials (complex to set up via opam)
            ocamlPackages.core
            ocamlPackages.core_unix
            ocamlPackages.async
            ocamlPackages.ppx_jane

            # Libraries for claude-tools
            ocamlPackages.yojson # JSON parsing
            ocamlPackages.cmdliner # Command-line parsing
            ocamlPackages.alcotest # Testing framework
            ocamlPackages.uuidm # UUID generation

            # Development tools
            ocamlPackages.utop # REPL with completion
            ocamlPackages.ocaml-lsp # LSP for neovim
            ocamlformat # Code formatter
            ocamlPackages.odoc # Documentation generation
          ]
          ++ packages.core.essential
          ++ packages.core.search
          ++ packages.core.utils;

        shellHook = ''
          echo "🐫 OCaml Development Environment"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "OCaml version: $(ocaml --version | head -n 1)"
          echo "Dune version: $(dune --version)"
          echo "Opam version: $(opam --version | head -n 1)"
          echo ""
          echo "Jane Street libraries included:"
          echo "  ✓ Core - Enhanced standard library"
          echo "  ✓ Async - Concurrent programming"
          echo "  ✓ PPX - Syntax extensions"
          echo ""
          echo "Quick start:"
          echo "  • utop                - Interactive REPL"
          echo "  • dune init project   - Create new project"
          echo "  • dune build         - Build project"
          echo "  • dune test          - Run tests"
          echo ""
          echo "Additional packages:"
          echo "  • opam install <package> - Install via opam"
          echo "  • opam search <keyword>  - Search packages"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

          # Create project structure if starting fresh
          if [ ! -f "dune-project" ]; then
            echo ""
            echo "💡 No dune-project found. Create a new project with:"
            echo "   dune init project my_project"
          fi
        '';
      };
    });
}

