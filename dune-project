(lang dune 3.20)

(name claude-tools)

(generate_opam_files true)

(source
 (github dlond/claude-tools))

(authors "Author D <dlond@me.com>")

(maintainers "Maintainer D <dlond@me.com>")

(license "MIT")

(documentation https://url/to/documentation)

(package
 (name claude-tools)
 (synopsis "Unix-like tools for Claude Code conversations")
 (description "Manage Claude Code conversations with familiar commands")
 (depends
   ocaml
   dune
   yojson
   cmdliner
   uuidm
   (alcotest :with-test)
   ;; Development tools
   (ocaml-lsp-server :with-dev-setup)
   (merlin :with-dev-setup)
   (ocamlformat :with-dev-setup)
   (utop :with-dev-setup))
 (tags
  ("add topics" "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
