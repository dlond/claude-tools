open Claude_tools_lib.Cvfs

type mode =
  | Copy of string option  (* Copy mode with optional ID *)
  | List                   (* List available conversations *)

let print_conversation_list conversations =
  conversations
  |> List.iter (fun conv ->
    let time = Unix.gmtime conv.timestamp in
    Printf.printf "%s\t%04d-%02d-%02dT%02d:%02d:%02dZ\t%s\n"
      conv.id
      (time.tm_year + 1900) (time.tm_mon + 1) time.tm_mday
      time.tm_hour time.tm_min time.tm_sec
      conv.summary)

let copy_with_id source dest id dry_run verbose exec =
  if verbose && not dry_run then
    Printf.eprintf "Copying conversation '%s' from %s to %s\n" id source dest;

  if dry_run then (
    match find_by_id source id with
    | None ->
        Printf.eprintf "Error: Conversation '%s' not found in %s\n" id source;
        exit 1
    | Some conv ->
        if verbose then
          Printf.eprintf "Would copy: %s\n" conv.id;
        print_endline conv.id;
        exit 0
  );

  match copy_conversation source id dest with
  | Error msg ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
  | Ok conv_id ->
      print_endline conv_id;

      if exec then (
        let dest_abs = resolve_path dest in
        let cmd = Printf.sprintf "cd %s && claude --resume %s"
          (Filename.quote dest_abs) conv_id in
        exit (Sys.command cmd)
      );
      exit 0

let main () =
  let args = Array.to_list Sys.argv |> List.tl in

  (* Parse flags and positional args *)
  let rec parse_args flags pos = function
    | [] -> (flags, List.rev pos)
    | "--" :: rest -> (flags, List.rev pos @ ["--"] @ rest)  (* -- is special *)
    | arg :: rest when String.starts_with ~prefix:"--" arg ->
        parse_args (arg :: flags) pos rest
    | arg :: rest ->
        parse_args flags (arg :: pos) rest
  in

  let flags, positional = parse_args [] [] args in
  let dry_run = List.mem "--dry-run" flags in
  let verbose = List.mem "--verbose" flags in
  let exec = List.mem "--exec" flags in
  let complete_source = List.mem "--complete-source" flags in

  (* Handle completion mode *)
  if complete_source then (
    let sources = get_all_sources () in
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

  (* Determine mode and arguments *)
  let mode, source, dest = match positional with
    | [source; dest; "--"] -> (List, source, dest)
    | [source; dest; id] -> (Copy (Some id), source, dest)
    | [source; dest] -> (Copy None, source, dest)
    | _ ->
        Printf.eprintf "Usage: claude-cp SOURCE DEST [ID | --]\n";
        Printf.eprintf "       claude-cp SOURCE DEST        # Copy most recent\n";
        Printf.eprintf "       claude-cp SOURCE DEST ID     # Copy specific conversation\n";
        Printf.eprintf "       claude-cp SOURCE DEST --     # List available conversations\n";
        Printf.eprintf "\nFlags:\n";
        Printf.eprintf "  --dry-run   Show what would be done without doing it\n";
        Printf.eprintf "  --verbose   Show detailed output\n";
        Printf.eprintf "  --exec      Launch Claude after copying\n";
        exit 1
  in

  match mode with
  | List ->
      let conversations = list source in
      if conversations = [] then (
        Printf.eprintf "No conversations found in %s\n" source;
        exit 1
      );
      print_conversation_list conversations

  | Copy id_opt ->
      (* Determine which conversation to copy *)
      let id_to_copy = match id_opt with
        | Some id -> id
        | None ->
            (* Try to read from stdin if it's not a tty OR if select shows data *)
            let try_stdin =
              if not (Unix.isatty Unix.stdin) then
                (* Not a tty - might be piped, but also might be empty *)
                try
                  let id = input_line stdin |> String.trim in
                  if id = "" then None else Some id
                with End_of_file -> None
              else
                None
            in

            match try_stdin with
            | Some id -> id
            | None ->
                (* No stdin data, use most recent *)
                match get_most_recent source with
                | None ->
                    Printf.eprintf "Error: No conversations found in %s\n" source;
                    exit 1
                | Some conv ->
                    if verbose then
                      Printf.eprintf "Using most recent conversation: %s\n" conv.id;
                    conv.id
      in

      copy_with_id source dest id_to_copy dry_run verbose exec

let () = main ()