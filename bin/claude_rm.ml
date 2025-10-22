open Claude_tools_lib.Cvfs

let main () =
  let args = Array.to_list Sys.argv |> List.tl in

  match args with
  | [path; id] ->
      (* Support "-" for most recent *)
      let id_to_remove =
        if id = "-" then
          match get_most_recent path with
          | None ->
              Printf.eprintf "Error: No conversations found in %s\n" path;
              exit 1
          | Some conv -> conv.id
        else
          id
      in

      (* Remove the conversation *)
      (match remove_conversation path id_to_remove with
      | Ok removed_id ->
          Printf.printf "%s\n" removed_id;
          exit 0
      | Error msg ->
          Printf.eprintf "%s\n" msg;
          exit 1)

  | _ ->
      Printf.eprintf "Usage: claude-rm PATH ID\n";
      Printf.eprintf "       claude-rm PATH -     # Remove most recent\n";
      Printf.eprintf "\nRemove a conversation from a project.\n";
      exit 1

let () = main ()