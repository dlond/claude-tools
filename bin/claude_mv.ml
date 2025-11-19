open Claude_tools_lib.Cvfs

let print_help () =
  Printf.printf "Usage: claude-mv SOURCE DEST [ID]\n";
  Printf.printf "Move Claude Code conversations between project directories.\n\n";
  Printf.printf "Arguments:\n";
  Printf.printf "  SOURCE              Source project directory\n";
  Printf.printf "  DEST                Destination project directory\n";
  Printf.printf "  ID                  Specific conversation ID to move (optional)\n";
  Printf.printf "                      Use '-' to explicitly select most recent\n\n";
  Printf.printf "If no ID is provided, moves the most recent conversation.\n";
  Printf.printf "Unlike claude-cp, this preserves the conversation's UUID.\n\n";
  Printf.printf "Options:\n";
  Printf.printf "  -h, --help          Show this help message and exit\n\n";
  Printf.printf "Examples:\n";
  Printf.printf "  claude-mv ~/proj1 ~/proj2           # Move most recent conversation\n";
  Printf.printf "  claude-mv ~/proj1 ~/proj2 abc123    # Move specific conversation\n";
  Printf.printf "  claude-mv ~/proj1 ~/proj2 -         # Move most recent (explicit)\n"

let main () =
  let args = Array.to_list Sys.argv |> List.tl in

  (* Check for help flag *)
  if List.mem "--help" args || List.mem "-h" args then (
    print_help ();
    exit 0
  );

  match args with
  | [source; dest; id] ->
      (* Support "-" for most recent *)
      let id_to_move =
        if id = "-" then
          match get_most_recent source with
          | None ->
              Printf.eprintf "Error: No conversations found in %s\n" source;
              exit 1
          | Some conv -> conv.id
        else
          id
      in

      (* Move the conversation *)
      (match move_conversation source id_to_move dest with
      | Ok moved_id ->
          Printf.printf "%s\n" moved_id;
          exit 0
      | Error msg ->
          Printf.eprintf "%s\n" msg;
          exit 1)

  | [source; dest] ->
      (* Default to most recent if no ID specified *)
      (match get_most_recent source with
      | None ->
          Printf.eprintf "Error: No conversations found in %s\n" source;
          exit 1
      | Some conv ->
          match move_conversation source conv.id dest with
          | Ok moved_id ->
              Printf.printf "%s\n" moved_id;
              exit 0
          | Error msg ->
              Printf.eprintf "%s\n" msg;
              exit 1)

  | _ ->
      Printf.eprintf "Usage: claude-mv SOURCE DEST [ID]\n";
      Printf.eprintf "       claude-mv SOURCE DEST        # Move most recent\n";
      Printf.eprintf "       claude-mv SOURCE DEST ID     # Move specific conversation\n";
      Printf.eprintf "       claude-mv SOURCE DEST -      # Move most recent (explicit)\n";
      Printf.eprintf "\nMove a conversation between projects (keeps same ID).\n";
      exit 1

let () = main ()