(lang dune 3.24)

(name time-wind-ocaml)

(generate_opam_files true)

(source
 (github username/reponame))

(authors "Author Name <author@example.com>")

(maintainers "Maintainer Name <maintainer@example.com>")

(license LICENSE)

(documentation https://url/to/documentation)

(package
 (name time-wind-ocaml)
 (synopsis "A short synopsis")
 (description "A longer description")
 (depends 
   (ocaml (>= "5.4.0"))
   bogue
   cohttp-lwt-unix
   cohttp-async
   yojson)
(tags
  ("add topics" "to describe" your project)))

; See the complete stanza docs at https://dune.readthedocs.io/en/stable/reference/dune-project/index.html
