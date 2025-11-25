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
            echo "🐪 No project opam switches found. Creating ..."

            # worktrees just link switches
            if [ -f ".git" ]; then
              MAIN_WT=$(git worktree list | awk 'NR == 1 { print $1; exit }')
              echo "   Linking project opam switch at $MAIN_WT ..."
              opam switch link $MAIN_WT
            else
              echo "  Creating project opam switch $PWD with ocaml-base-compiler.5.4.0 ..."
              opam switch create "$PWD" ocaml-base-compiler.5.4.0

              # Prime the env for this first session only
              eval $(opam env --switch="$PWD" --set-switch)

              opam install -y \
                dune \
                utop \
                ocaml-lsp-server \
                ocamlformat \
                odoc

              echo "  Creating claude-tools.opam"
              dune build >/dev/null 2>&1

              echo "  Installing all project dependencies"
              opam install -y . --deps-only --with-test --with-dev-setup

              echo "✅ Project switch created."
            fi
            echo "  From now on, direnv will activate the switch when you cd here."
            echo ""
          fi

          echo "🐫 OCaml Development Environment"
          echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
          echo "OCaml version: $(ocaml -vnum)"
          echo "Dune version: $(dune --version)"
          echo "Opam version: $(opam --version)"
        '';
      };
    });
}
