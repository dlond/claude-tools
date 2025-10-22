open Claude_tools_lib

let () =
  (* Check for completion mode *)
  if Array.length Sys.argv > 1 && Sys.argv.(1) = "--complete" then (
    let sources = Cvfs.get_all_sources () in
    sources |> List.iter (fun (path, is_ghost, count, last_modified) ->
      let ghost_marker = if is_ghost then " (ghost)" else "" in
      let time_ago =
        let now = Unix.time () in
        let diff = now -. last_modified in
        if diff < 3600.0 then Printf.sprintf "%.0f min ago" (diff /. 60.0)
        else if diff < 86400.0 then Printf.sprintf "%.0f hours ago" (diff /. 3600.0)
        else Printf.sprintf "%.0f days ago" (diff /. 86400.0)
      in
      Printf.printf "%s\t%d conversations, last: %s%s\n"
        path count time_ago ghost_marker
    );
    exit 0
  );

  (* Simple argument parsing for now *)
  let path = if Array.length Sys.argv > 1 then Sys.argv.(1) else "." in

  try
    let conversations = Cvfs.list path in
    if conversations = [] then
      Printf.printf "No conversations found in %s\n" path
    else Display.print_short conversations
  with
  | Sys_error msg ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
  | e ->
      Printf.eprintf "Unexpected error: %s\n" (Printexc.to_string e);
      exit 1
