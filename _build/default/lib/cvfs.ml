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

  (* Shortcut easy case *)
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

let project_path path =
  path |> resolve_path |> String.map (fun c -> if c = '/' then '-' else c)
  |> fun dir -> Sys.getenv "HOME" ^ "/.claude/projects/" ^ dir

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
            summary = "(No summary yet)";
            (* We'll add parsing next *)
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

let copy_conversation _source_path _id _dest_path =
  (* TODO: Implement actual copying *)
  failwith "copy_conversation: not yet implemented"
