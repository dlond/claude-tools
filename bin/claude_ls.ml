open Claude_tools_lib

let print_help () =
  Printf.printf "Usage: claude-ls [PATH]...\n";
  Printf.printf "List Claude Code conversations in project directories.\n\n";
  Printf.printf "If no PATH is specified, lists conversations in the current directory.\n";
  Printf.printf "If multiple PATHs are specified, lists conversations in each directory.\n\n";
  Printf.printf "Options:\n";
  Printf.printf "  -h, --help      Show this help message and exit\n";
  Printf.printf "  --complete      Print completion-friendly output\n\n";
  Printf.printf "Examples:\n";
  Printf.printf "  claude-ls                    # List conversations in current directory\n";
  Printf.printf "  claude-ls ~/project          # List conversations in specific directory\n";
  Printf.printf "  claude-ls ~/proj1 ~/proj2    # List conversations in multiple directories\n"

let () =
  (* Check for help flag *)
  if Array.length Sys.argv > 1 && (Sys.argv.(1) = "--help" || Sys.argv.(1) = "-h") then (
    print_help ();
    exit 0
  );

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

  (* Get all path arguments (or current directory if none) *)
  let paths =
    if Array.length Sys.argv > 1 then
      Array.sub Sys.argv 1 (Array.length Sys.argv - 1) |> Array.to_list
    else
      ["."]
  in

  (* Process each path *)
  let show_headers = List.length paths > 1 in
  let had_output = ref false in

  paths |> List.iter (fun path ->
    try
      (* Print directory header if multiple paths *)
      if show_headers then (
        if !had_output then print_newline ();
        Printf.printf "%s:\n" path
      );

      let conversations = Cvfs.list path in
      if conversations = [] then
        Printf.printf "No conversations found in %s\n" path
      else (
        Display.print_short conversations;
        had_output := true
      )
    with
    | Sys_error msg ->
        Printf.eprintf "Error reading %s: %s\n" path msg;
        had_output := true
    | e ->
        Printf.eprintf "Error reading %s: %s\n" path (Printexc.to_string e);
        had_output := true
  )
