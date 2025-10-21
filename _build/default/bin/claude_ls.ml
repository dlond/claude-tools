open Claude_tools_lib

let () =
  (* Simple argument parsing for now *)
  let path =
    if Array.length Sys.argv > 1 then
      Sys.argv.(1)
    else
      "."
  in

  try
    let conversations = Cvfs.list path in
    if conversations = [] then
      Printf.printf "No conversations found in %s\n" path
    else
      Display.print_short conversations
  with
  | Sys_error msg ->
      Printf.eprintf "Error: %s\n" msg;
      exit 1
  | e ->
      Printf.eprintf "Unexpected error: %s\n" (Printexc.to_string e);
      exit 1