(** Display functions for conversation output *)

val print_short : Cvfs.conversation list -> unit
(** Print conversations in short format (default) *)

val print_long : Cvfs.conversation list -> unit
(** Print conversations in long format (with -l flag) *)