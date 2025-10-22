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

val copy_conversation : string -> string -> string -> (string, string) result
(** Copy a conversation from one project to another.
    Returns Ok(conversation_id) on success or Error(message) on failure *)

val get_most_recent : string -> conversation option
(** Get the most recent conversation from a project *)

val project_path : string -> string
(** Resolve project path to Claude directory *)

val resolve_path : string -> string
(** Resolve and normalize a path *)

val reverse_project_path : string -> string
(** Reverse map an encoded project directory name to original path *)

val list_all_projects : unit -> (string * bool * int * float) list
(** Get all project directories from ~/.claude/projects.
    Returns list of (path, is_ghost, conversation_count, last_modified) *)

val discover_ghosts : unit -> (string * bool * int * float) list
(** Discover ghost directories (have conversations but directory doesn't exist).
    Returns list of (path, is_ghost, conversation_count, last_modified) *)

val get_all_sources : unit -> (string * bool * int * float) list
(** Get all available sources (real + ghost directories with conversations).
    Returns list of (path, is_ghost, conversation_count, last_modified) *)

val remove_conversation : string -> string -> (string, string) result
(** Remove a conversation from a project.
    Returns Ok(conversation_id) on success or Error(message) on failure *)

val move_conversation : string -> string -> string -> (string, string) result
(** Move a conversation from one project to another (keeps same ID).
    Returns Ok(conversation_id) on success or Error(message) on failure *)

val find_orphans : ?days_old:int -> unit -> (string * string * int * float * int * bool) list
(** Find empty or stale project directories.
    Returns list of (path, encoded_name, conversation_count, last_modified, size_bytes, is_ghost)
    Default days_old is 30 *)

val remove_orphan : string -> (unit, string) result
(** Remove an orphaned project directory by its encoded name.
    Returns Ok() on success or Error(message) on failure *)
