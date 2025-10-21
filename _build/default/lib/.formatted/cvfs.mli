(** Claude Virtual File System (CVFS) interface *)

type conversation = {
  id : string;
  summary : string;
  timestamp : float;
  path : string;
}

val list : ?show_all:bool -> string -> conversation list
(** List conversations in a project directory *)

val find_by_id : string -> string -> conversation option
(** Find a conversation by ID in a project *)

val copy_conversation : string -> string -> string -> unit
(** Copy a conversation from one project to another *)

val project_path : string -> string
(** Resolve project path to Claude directory *)

val resolve_path : string -> string
(** Resolve and normalize a path *)
