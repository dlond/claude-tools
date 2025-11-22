{
  description = "OCaml development environment for claude-tools";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    nixpkgs,
    flake-utils,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (system: let
      pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
      };

      # More useful stuff here I guess
      config = {
        name = "OCaml Development";
        withTest = true;
      };

      packages = with pkgs; [
        opam

        gnumake
        pkg-config
        git
      ];
    in {
      devShells.default = pkgs.mkShell {
        name = config.name;
        nativeBuildInputs = packages;
        ENV_ICON = "❄️";

        shellHook = ''
          if [ ! -d "./_opam" ]; then
            echo "🐪 No local opam switch found for this project."
            echo "  Creating local switch '.' with ocaml-base-compiler.5.4.0 ..."
            opam switch create . ocaml-base-compiler.5.4.0

            # Prime the env for this first session only
            eval "$(opam env --switch=. --set-switch)"

            opam install -y \
              dune \
              utop \
              ocaml-lsp-server \
              ocamlformat \
              odoc

            echo "  Creating claude-tools.opam"
            dune build >/dev/null 2>&1

            echo "  Installing project dependencies"
            opam install -y . --deps-only --with-test --with-dev-setup

            echo "  Building project files"
            dune build

            echo "  All dependencies should be installed. Running tests"
            dune test

            echo "✅ Local switch create."
            echo "  From now on, .envrc will auto load it when you cd here."
            echo ""
          fi

          echo "🐫 OCaml Development Environment"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          if command -v ocaml >/dev/null 2>&1; then
            echo "OCaml version: $(ocaml -vnum)"
          fi
          if command -v dune >/dev/null 2>&1; then
            echo "Dune version: $(dune --version)"
          fi
          echo "Opam version: $(opam --version)"
          echo ""
        '';
      };
    });
}
