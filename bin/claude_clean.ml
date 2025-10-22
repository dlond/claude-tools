open Claude_tools_lib.Cvfs

let format_size bytes =
  if bytes < 1024 then Printf.sprintf "%d B" bytes
  else if bytes < 1024 * 1024 then Printf.sprintf "%.1f KB" (float_of_int bytes /. 1024.0)
  else Printf.sprintf "%.1f MB" (float_of_int bytes /. 1024.0 /. 1024.0)

let format_age timestamp =
  let now = Unix.time () in
  let diff = now -. timestamp in
  let days = int_of_float (diff /. 86400.0) in
  if days = 0 then "today"
  else if days = 1 then "1 day ago"
  else Printf.sprintf "%d days ago" days

let main () =
  let args = Array.to_list Sys.argv |> List.tl in

  (* Parse flags *)
  let rec parse_flags acc = function
    | [] -> (acc, [])
    | arg :: rest when String.starts_with ~prefix:"--" arg ->
        parse_flags (arg :: acc) rest
    | rest -> (acc, rest)
  in

  let flags, _positional = parse_flags [] args in
  let dry_run = not (List.mem "--execute" flags) in  (* Default to dry-run *)
  let empty_only = List.mem "--empty-only" flags in
  let verbose = List.mem "--verbose" flags in

  (* Parse days parameter *)
  let days =
    try
      match List.find_opt (String.starts_with ~prefix:"--days=") flags with
      | Some flag ->
          let value = String.sub flag 7 (String.length flag - 7) in
          int_of_string value
      | None -> 30
    with _ -> 30
  in

  (* Find orphans *)
  let orphans = find_orphans ~days_old:days () in

  (* Filter if requested *)
  let orphans_to_process =
    if empty_only then
      List.filter (fun (_, _, count, _, _, _) -> count = 0) orphans
    else
      orphans
  in

  if orphans_to_process = [] then (
    Printf.printf "No orphaned projects found (checked for %d+ days old)\n" days;
    exit 0
  );

  (* Group by type *)
  let empty, stale =
    List.partition (fun (_, _, count, _, _, _) -> count = 0) orphans_to_process
  in

  (* Calculate total size *)
  let total_size =
    List.fold_left (fun acc (_, _, _, _, size, _) -> acc + size) 0 orphans_to_process
  in

  (* Display what would be/was done *)
  if dry_run then
    Printf.printf "Would remove %d project%s:\n\n"
      (List.length orphans_to_process)
      (if List.length orphans_to_process = 1 then "" else "s")
  else
    Printf.printf "Removing %d project%s:\n\n"
      (List.length orphans_to_process)
      (if List.length orphans_to_process = 1 then "" else "s");

  (* Show empty projects *)
  if empty <> [] then (
    Printf.printf "Empty projects (%d):\n" (List.length empty);
    List.iter (fun (path, _encoded, _, mtime, size, is_ghost) ->
      let ghost_marker = if is_ghost then " (ghost)" else "" in
      if verbose then
        Printf.printf "  %s%s\n    Last modified: %s, Size: %s\n"
          path ghost_marker (format_age mtime) (format_size size)
      else
        Printf.printf "  %s%s (%s)\n"
          path ghost_marker (format_age mtime)
    ) empty;
    print_newline ()
  );

  (* Show stale projects *)
  if stale <> [] then (
    Printf.printf "Stale projects (%d):\n" (List.length stale);
    List.iter (fun (path, _encoded, count, mtime, size, is_ghost) ->
      let ghost_marker = if is_ghost then " (ghost)" else "" in
      if verbose then
        Printf.printf "  %s%s\n    %d conversation%s, Last: %s, Size: %s\n"
          path ghost_marker count (if count = 1 then "" else "s")
          (format_age mtime) (format_size size)
      else
        Printf.printf "  %s%s (%d conversation%s, %s)\n"
          path ghost_marker count (if count = 1 then "" else "s")
          (format_age mtime)
    ) stale;
    print_newline ()
  );

  Printf.printf "Total space to reclaim: %s\n" (format_size total_size);

  if dry_run then (
    Printf.printf "\nRun with --execute to actually remove these projects.\n";
    exit 0
  ) else (
    (* Actually remove the directories *)
    print_newline ();
    let failed = ref [] in
    List.iter (fun (path, encoded, _, _, _, _) ->
      Printf.printf "Removing %s..." path;
      flush stdout;
      match remove_orphan encoded with
      | Ok () -> Printf.printf " done\n"
      | Error msg ->
          Printf.printf " failed: %s\n" msg;
          failed := path :: !failed
    ) orphans_to_process;

    if !failed <> [] then (
      Printf.printf "\nFailed to remove %d project%s:\n"
        (List.length !failed)
        (if List.length !failed = 1 then "" else "s");
      List.iter (Printf.printf "  %s\n") !failed;
      exit 1
    ) else (
      Printf.printf "\nSuccessfully removed %d project%s.\n"
        (List.length orphans_to_process)
        (if List.length orphans_to_process = 1 then "" else "s");
      exit 0
    )
  )

let () = main ()