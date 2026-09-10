(lang dune 3.24)

(name splc)

(generate_opam_files true)

(package
 (name splc)
 (depends
  (ocaml
   (and
    (>= 5.5.0)
    (< 5.6.0)))
  ppx_string
  ppx_deriving
  yojson
  (ocaml-lsp-server :with-dev-setup)
  (ocamlformat :with-dev-setup)))
