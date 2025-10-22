type conversation = {
  id : string;
  summary : string;
  timestamp : float;
  path : string;
}

let resolve_path path =
  let clean_parts parts =
    let squash_rev acc s =
      match s with
      | ".." -> ( match acc with [] -> [] | _ -> List.tl acc)
      | "" | "." -> acc
      | _ -> s :: acc
    in
    List.rev (List.fold_left squash_rev [] parts)
  in

  (* First resolve to absolute path *)
  let abs_path =
    if path = "" || path = "." then Sys.getcwd ()
    else if path = "~" then Sys.getenv "HOME"
    else if path.[0] = '/' then
      (* Absolute path *)
      let parts = String.split_on_char '/' path |> clean_parts in
      "/" ^ String.concat "/" parts
    else if String.starts_with ~prefix:"~/" path then
      (* Home directory *)
      let rest = String.sub path 2 (String.length path - 2) in
      let path_abs = Sys.getenv "HOME" ^ "/" ^ rest in
      let parts = String.split_on_char '/' path_abs |> clean_parts in
      "/" ^ String.concat "/" parts
    else
      (* Relative path *)
      let path_abs = Sys.getcwd () ^ "/" ^ path in
      let parts = String.split_on_char '/' path_abs |> clean_parts in
      "/" ^ String.concat "/" parts
  in

  (* Resolve symlinks using realpath *)
  try
    Unix.realpath abs_path
  with _ ->
    (* If realpath fails (e.g., path doesn't exist), return the cleaned path *)
    abs_path

let project_path path =
  path |> resolve_path |> String.map (fun c -> if c = '/' then '-' else c)
  |> fun dir -> Sys.getenv "HOME" ^ "/.claude/projects/" ^ dir

let get_session_summary filepath =
  try
    let ic = open_in filepath in
    let rec scan_lines summaries =
      try
        let line = input_line ic in
        let json = Yojson.Safe.from_string line in
        match Yojson.Safe.Util.(member "type" json |> to_string_option) with
        | Some "summary" ->
            Yojson.Safe.Util.(member "summary" json |> to_string) :: summaries
            |> scan_lines
        | _ -> scan_lines summaries
      with
      | End_of_file ->
          close_in ic;
          summaries
      | _ -> scan_lines summaries
    in
    [] |> scan_lines
  with _ -> [ "(Error reading file)" ]

let list ?show_all:(_ = false) path =
  let proj = project_path path in
  (* Check if directory exists *)
  if not (Sys.file_exists proj) then []
  else
    let files =
      Sys.readdir proj |> Array.to_list
      |> List.filter (fun f -> Filename.check_suffix f "jsonl")
      |> List.map (fun f -> Filename.concat proj f)
    in
    (* Convert filenames to conversations *)
    let conversations =
      List.map
        (fun filepath ->
          let id = Filename.basename filepath |> Filename.remove_extension in
          let stats = Unix.stat filepath in
          {
            id;
            summary =
              (match get_session_summary filepath with
              | [] -> "(No summary)"
              | summaries -> summaries |> List.rev |> List.hd);
            (* summary = *)
            (*   (match get_session_summary filepath with *)
            (*   | [] -> "(No summaries found)" *)
            (*   | [ s ] -> s *)
            (*   | ls -> String.concat " -> " ls); *)
            timestamp = stats.Unix.st_mtime;
            path;
          })
        files
    in
    (* Sort by timestamp, newest first *)
    List.sort (fun a b -> compare b.timestamp a.timestamp) conversations

let find_by_id path id =
  let conversations = list path in
  List.find_opt
    (fun c -> c.id = id || String.starts_with ~prefix:id c.id)
    conversations

let copy_conversation source_path id dest_path =
  match find_by_id source_path id with
  | None -> Error (Printf.sprintf "Conversation '%s' not found in %s" id source_path)
  | Some conv ->
      (* Check if destination directory exists *)
      if not (Sys.file_exists dest_path) then
        Error (Printf.sprintf "Error: destination directory '%s' does not exist" dest_path)
      else if not (Sys.is_directory dest_path) then
        Error (Printf.sprintf "Error: destination '%s' is not a directory" dest_path)
      else
        let source_proj = project_path source_path in
        let dest_proj = project_path dest_path in
        let source_file = Filename.concat source_proj (conv.id ^ ".jsonl") in

        (* Generate new UUID for the copy *)
        let new_id = Uuidm.v4_gen (Random.State.make_self_init ()) () |> Uuidm.to_string ~upper:false in
        let dest_file = Filename.concat dest_proj (new_id ^ ".jsonl") in

          try
            (* Create Claude project directory if it doesn't exist *)
            if not (Sys.file_exists dest_proj) then (
              (* Create parent directories if needed *)
              let claude_dir = Sys.getenv "HOME" ^ "/.claude" in
              let projects_dir = claude_dir ^ "/projects" in
              if not (Sys.file_exists claude_dir) then Unix.mkdir claude_dir 0o755;
              if not (Sys.file_exists projects_dir) then Unix.mkdir projects_dir 0o755;
              Unix.mkdir dest_proj 0o755
            );

            (* Copy the file *)
            let ic = open_in_bin source_file in
            let oc = open_out_bin dest_file in
            let buffer = Bytes.create 8192 in
            let rec copy_loop () =
              match input ic buffer 0 8192 with
              | 0 -> ()
              | n ->
                  output oc buffer 0 n;
                  copy_loop ()
            in
            copy_loop ();
            close_in ic;

            (* Append metadata about the copy operation *)
            let metadata =
              `Assoc [
                ("type", `String "metadata");
                ("tool", `String "claude-cp");
                ("action", `String "copy");
                ("timestamp", `String (
                  let time = Unix.gettimeofday () |> Unix.gmtime in
                  Printf.sprintf "%04d-%02d-%02dT%02d:%02d:%02dZ"
                    (time.tm_year + 1900) (time.tm_mon + 1) time.tm_mday
                    time.tm_hour time.tm_min time.tm_sec
                ));
                ("source_path", `String source_path);
                ("dest_path", `String dest_path);
                ("source_id", `String conv.id);
                ("version", `String "1.0.0");
              ]
            in
            output_string oc "\n";
            output_string oc (Yojson.Safe.to_string metadata);
            output_string oc "\n";
            close_out oc;

            (* Update all sessionId references to the new UUID *)
            let sed_cmd = Printf.sprintf
              "sed -i.bak 's/\"sessionId\":\"[^\"]*\"/\"sessionId\":\"%s\"/g' %s && rm %s.bak"
              new_id (Filename.quote dest_file) (Filename.quote dest_file) in
            let _ = Sys.command sed_cmd in

            (* Preserve timestamps *)
            let stats = Unix.stat source_file in
            Unix.utimes dest_file stats.st_atime stats.st_mtime;

            Ok new_id
          with
          | e -> Error (Printf.sprintf "Failed to copy: %s" (Printexc.to_string e))

let get_most_recent path =
  match list path with
  | [] -> None
  | h :: _ -> Some h  (* list is already sorted by timestamp, newest first *)

(* Reverse map an encoded project directory name to original path *)
let reverse_project_path encoded_name =
  encoded_name |> String.map (fun c -> if c = '-' then '/' else c)

(* Get all project directories from ~/.claude/projects *)
let list_all_projects () =
  let projects_dir = Sys.getenv "HOME" ^ "/.claude/projects" in
  if not (Sys.file_exists projects_dir) then []
  else
    Sys.readdir projects_dir
    |> Array.to_list
    |> List.filter (fun name ->
      (* Filter out non-directory entries if any *)
      let full_path = Filename.concat projects_dir name in
      Sys.is_directory full_path
    )
    |> List.map (fun encoded ->
      let path = reverse_project_path encoded in
      let is_ghost = not (Sys.file_exists path) in
      let conversations = list path in
      let conversation_count = List.length conversations in
      let last_modified =
        match conversations with
        | [] -> 0.0
        | h :: _ -> h.timestamp
      in
      (path, is_ghost, conversation_count, last_modified)
    )

(* Discover ghost directories (have conversations but directory doesn't exist) *)
let discover_ghosts () =
  list_all_projects ()
  |> List.filter (fun (_, is_ghost, count, _) -> is_ghost && count > 0)

(* Get all available sources (real + ghost directories) *)
let get_all_sources () =
  list_all_projects ()
  |> List.filter (fun (_, _, count, _) -> count > 0)

(* Remove a conversation *)
let remove_conversation path id =
  match find_by_id path id with
  | None -> Error (Printf.sprintf "Conversation '%s' not found in %s" id path)
  | Some conv ->
      let proj = project_path path in
      let file = Filename.concat proj (conv.id ^ ".jsonl") in
      try
        Unix.unlink file;
        Ok conv.id
      with
      | e -> Error (Printf.sprintf "Failed to remove: %s" (Printexc.to_string e))

(* Move a conversation (keeps same ID, no copy) *)
let move_conversation source_path id dest_path =
  match find_by_id source_path id with
  | None -> Error (Printf.sprintf "Conversation '%s' not found in %s" id source_path)
  | Some conv ->
      (* Check if destination directory exists *)
      if not (Sys.file_exists dest_path) then
        Error (Printf.sprintf "Error: destination directory '%s' does not exist" dest_path)
      else if not (Sys.is_directory dest_path) then
        Error (Printf.sprintf "Error: destination '%s' is not a directory" dest_path)
      else
        let source_proj = project_path source_path in
        let dest_proj = project_path dest_path in
        let source_file = Filename.concat source_proj (conv.id ^ ".jsonl") in
        let dest_file = Filename.concat dest_proj (conv.id ^ ".jsonl") in

        try
          (* Create destination Claude project directory if needed *)
          if not (Sys.file_exists dest_proj) then (
            let claude_dir = Sys.getenv "HOME" ^ "/.claude" in
            let projects_dir = claude_dir ^ "/projects" in
            if not (Sys.file_exists claude_dir) then Unix.mkdir claude_dir 0o755;
            if not (Sys.file_exists projects_dir) then Unix.mkdir projects_dir 0o755;
            Unix.mkdir dest_proj 0o755
          );

          (* Check if destination file already exists *)
          if Sys.file_exists dest_file then
            Error (Printf.sprintf "Conversation '%s' already exists in destination" conv.id)
          else (
            (* Move the file *)
            Unix.rename source_file dest_file;

            (* Add metadata about the move *)
            let oc = open_out_gen [Open_append; Open_creat] 0o644 dest_file in
            let metadata =
              `Assoc [
                ("type", `String "metadata");
                ("tool", `String "claude-mv");
                ("action", `String "move");
                ("timestamp", `String (
                  let time = Unix.gettimeofday () |> Unix.gmtime in
                  Printf.sprintf "%04d-%02d-%02dT%02d:%02d:%02dZ"
                    (time.tm_year + 1900) (time.tm_mon + 1) time.tm_mday
                    time.tm_hour time.tm_min time.tm_sec
                ));
                ("source_path", `String source_path);
                ("dest_path", `String dest_path);
                ("source_id", `String conv.id);
                ("version", `String "1.0.0");
              ]
            in
            output_string oc "\n";
            output_string oc (Yojson.Safe.to_string metadata);
            output_string oc "\n";
            close_out oc;

            Ok conv.id
          )
        with
        | e -> Error (Printf.sprintf "Failed to move: %s" (Printexc.to_string e))

(* Find empty or stale project directories *)
let find_orphans ?(days_old=30) () =
  let projects_dir = Sys.getenv "HOME" ^ "/.claude/projects" in
  if not (Sys.file_exists projects_dir) then []
  else
    let cutoff_time = Unix.time () -. (float_of_int days_old *. 86400.0) in
    Sys.readdir projects_dir
    |> Array.to_list
    |> List.filter_map (fun encoded ->
      let full_path = Filename.concat projects_dir encoded in
      if not (Sys.is_directory full_path) then None
      else
        let path = reverse_project_path encoded in
        let is_ghost = not (Sys.file_exists path) in
        let conversations = list path in
        let count = List.length conversations in
        let stats = Unix.stat full_path in
        let last_modified =
          match conversations with
          | [] -> stats.st_mtime  (* Use directory mtime if empty *)
          | h :: _ -> h.timestamp  (* Use most recent conversation *)
        in
        (* Include if:
           1. Empty (no conversations)
           2. Stale (no activity in days_old)
           3. Ghost AND stale (deleted directory with old conversations) *)
        if count = 0 || last_modified < cutoff_time then
          let size =
            (* Calculate directory size *)
            try
              Sys.readdir full_path
              |> Array.fold_left (fun acc file ->
                let filepath = Filename.concat full_path file in
                try
                  let stats = Unix.stat filepath in
                  acc + stats.st_size
                with _ -> acc
              ) 0
            with _ -> 0
          in
          Some (path, encoded, count, last_modified, size, is_ghost)
        else None
    )

(* Remove an orphaned project directory *)
let remove_orphan encoded_name =
  let projects_dir = Sys.getenv "HOME" ^ "/.claude/projects" in
  let full_path = Filename.concat projects_dir encoded_name in
  try
    (* Remove all files in directory first *)
    Sys.readdir full_path
    |> Array.iter (fun file ->
      let filepath = Filename.concat full_path file in
      Unix.unlink filepath
    );
    (* Remove the directory *)
    Unix.rmdir full_path;
    Ok ()
  with
  | e -> Error (Printf.sprintf "Failed to remove: %s" (Printexc.to_string e))
