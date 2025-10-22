(lang dune 3.20)

(name claude-tools)

(generate_opam_files true)

(source
 (github dlond/claude-tools))

(authors "Author D <dlond@me.com>")

(maintainers "Maintainer D <dlond@me.com>")

(license LICENSE)

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
   alcotest)
 (tags
  ("add topics" "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
