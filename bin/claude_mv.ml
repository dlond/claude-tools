open Claude_tools_lib.Cvfs

let main () =
  let args = Array.to_list Sys.argv |> List.tl in

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