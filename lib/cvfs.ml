type conversation = {
  id : string;
  summary : string;
  timestamp : float;
  path : string;
}

let resolve_path path =
  let squash acc s =
    match s with
    | ".." -> (
        match acc with
        | [] -> []
        | _ -> List.rev (List.tl (List.rev acc)) (* Remove last element *))
    | "" | "." -> acc
    | _ -> acc @ [ s ]
  in

  (* Handle special input cases *)
  if path = "" || path = "." then Sys.getcwd ()
  else if path.[0] = '/' then
    (* Absolute path - clean it up *)
    let parts = String.split_on_char '/' path in
    let cleaned = List.fold_left squash [] parts in
    "/" ^ String.concat "/" (List.filter (fun s -> s <> "") cleaned)
  else if String.starts_with ~prefix:"~/" path then
    (* Home directory *)
    let rest = String.sub path 2 (String.length path - 2) in
    let parts = String.split_on_char '/' rest in
    let cleaned = List.fold_left squash [] parts in
    Sys.getenv "HOME" ^ "/"
    ^ String.concat "/" (List.filter (fun s -> s <> "") cleaned)
  else
    (* Relative path *)
    let parts = String.split_on_char '/' path in
    let cleaned = List.fold_left squash [] parts in
    if cleaned = [] then Sys.getcwd ()
    else Sys.getcwd () ^ "/" ^ String.concat "/" cleaned

let project_path path =
  path |> resolve_path |> String.map (fun c -> if c = '/' then '-' else c)
  |> fun dir -> Sys.getenv "HOME" ^ "/.claude/projects/" ^ dir

let list ?show_all:(_ = false) path =
  let proj = project_path path in
  (* Check if directory exists *)
  if not (Sys.file_exists proj) then
    []
  else
    let files =
      Sys.readdir proj |> Array.to_list
      |> List.filter (fun s -> Filename.check_suffix s "jsonl")
      |> List.map (fun filename -> Filename.concat proj filename)
    in
    (* Convert filenames to conversations *)
    let conversations = List.map (fun filepath ->
      let id = Filename.basename filepath |> Filename.remove_extension in
      let stats = Unix.stat filepath in
      {
        id;
        summary = "(No summary yet)";  (* We'll add parsing next *)
        timestamp = stats.Unix.st_mtime;
        path;
      }
    ) files in
    (* Sort by timestamp, newest first *)
    List.sort (fun a b -> compare b.timestamp a.timestamp) conversations

let find_by_id path id =
  let conversations = list path in
  List.find_opt (fun c ->
    c.id = id || String.starts_with ~prefix:id c.id
  ) conversations

let copy_conversation _source_path _id _dest_path =
  (* TODO: Implement actual copying *)
  failwith "copy_conversation: not yet implemented"
