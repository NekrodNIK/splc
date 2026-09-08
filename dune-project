(lang dune 3.24)

(name splc)

(generate_opam_files true)

(package
 (name splc)
 (depends
  (ocaml
   (>= 5.5.0))
  (astring
   (>= 0.8.5))
  (ocaml-lsp-server :with-dev-setup)
  (ocamlformat :with-dev-setup)))
