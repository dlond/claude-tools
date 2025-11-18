open Claude_tools_lib.Cvfs

(* Print conversation list for -- mode *)
let print_conversation_list conversations =
  conversations
  |> List.iter (fun conv ->
    let time = Unix.gmtime conv.timestamp in
    Printf.printf "%s\t%04d-%02d-%02dT%02d:%02d:%02dZ\t%s\n"
      conv.id
      (time.tm_year + 1900) (time.tm_mon + 1) time.tm_mday
      time.tm_hour time.tm_min time.tm_sec
      conv.summary)

(* Copy a specific conversation *)
let copy_with_id source dest id dry_run verbose exec_after =
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

      if exec_after then (
        let dest_abs = resolve_path dest in
        let cmd = Printf.sprintf "cd %s && claude --resume %s"
          (Filename.quote dest_abs) conv_id in
        exit (Sys.command cmd)
      )

(* Main copy logic *)
let run source dest id_or_list dry_run verbose exec_after complete_source =
  (* Handle completion mode first *)
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

  (* Check if in list mode *)
  match id_or_list with
  | Some "--" ->
      let conversations = list source in
      if conversations = [] then (
        Printf.eprintf "No conversations found in %s\n" source;
        exit 1
      );
      print_conversation_list conversations

  | Some id ->
      (* Copy specific ID *)
      copy_with_id source dest id dry_run verbose exec_after

  | None ->
      (* Try to read from stdin, or use most recent *)
      let id_to_copy =
        if not (Unix.isatty Unix.stdin) then
          (* Not a tty - might be piped *)
          try
            let id = input_line stdin |> String.trim in
            if id = "" then None else Some id
          with End_of_file -> None
        else
          None
      in

      match id_to_copy with
      | Some id ->
          copy_with_id source dest id dry_run verbose exec_after
      | None ->
          (* No stdin data, use most recent *)
          match get_most_recent source with
          | None ->
              Printf.eprintf "Error: No conversations found in %s\n" source;
              exit 1
          | Some conv ->
              if verbose then
                Printf.eprintf "Using most recent conversation: %s\n" conv.id;
              copy_with_id source dest conv.id dry_run verbose exec_after

(* Cmdliner argument definitions *)
open Cmdliner

let source_arg =
  let doc = "Source project directory" in
  Arg.(required & pos 0 (some string) None & info [] ~docv:"SOURCE" ~doc)

let dest_arg =
  let doc = "Destination project directory" in
  Arg.(required & pos 1 (some string) None & info [] ~docv:"DEST" ~doc)

let id_arg =
  let doc = "Conversation ID to copy, or '--' to list available conversations. \
             If not provided, copies the most recent conversation or reads ID from stdin." in
  Arg.(value & pos 2 (some string) None & info [] ~docv:"ID | --" ~doc)

let dry_run_flag =
  let doc = "Show what would be done without doing it" in
  Arg.(value & flag & info ["dry-run"] ~doc)

let verbose_flag =
  let doc = "Show detailed output" in
  Arg.(value & flag & info ["v"; "verbose"] ~doc)

let exec_flag =
  let doc = "Launch Claude after copying" in
  Arg.(value & flag & info ["exec"] ~doc)

let complete_source_flag =
  let doc = "Print completion-friendly output for sources (internal use)" in
  Arg.(value & flag & info ["complete-source"] ~doc)

let cmd =
  let doc = "copy Claude Code conversations between projects" in
  let man = [
    `S Manpage.s_description;
    `P "Copy Claude Code conversation files between project directories. \
        Creates a new conversation with a fresh UUID while preserving the content.";
    `P "If no ID is specified, copies the most recent conversation from the source. \
        Can also read conversation ID from stdin for use in pipes.";
    `S Manpage.s_examples;
    `P "Copy most recent conversation:";
    `Pre "  $(mname) ~/proj1 ~/proj2";
    `P "Copy specific conversation by ID:";
    `Pre "  $(mname) ~/proj1 ~/proj2 abc123";
    `P "List available conversations:";
    `Pre "  $(mname) ~/proj1 ~/proj2 --";
    `P "Preview without copying:";
    `Pre "  $(mname) ~/proj1 ~/proj2 --dry-run";
    `P "Copy and launch Claude:";
    `Pre "  $(mname) ~/proj1 ~/proj2 --exec";
    `P "Pipe with claude-ls:";
    `Pre "  claude-ls ~/proj1 | head -1 | cut -f1 | $(mname) ~/proj1 ~/proj2";
  ] in
  let info = Cmd.info "claude-cp" ~version:"1.0.1" ~doc ~man in
  Cmd.v info Term.(const run $ source_arg $ dest_arg $ id_arg $
                   dry_run_flag $ verbose_flag $ exec_flag $ complete_source_flag)

let () = exit (Cmd.eval cmd)
