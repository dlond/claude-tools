open Claude_tools_lib

let test_resolve_path () =
  let home = Sys.getenv "HOME" in
  let cwd = Sys.getcwd () in
  let parent_cwd = Filename.dirname cwd in

  let test_cases = [
    (* Basic cases *)
    (".", cwd);
    ("", cwd);
    ("./", cwd);

    (* Absolute paths *)
    ("/", "/");
    ("/foo", "/foo");
    ("/foo/bar", "/foo/bar");
    ("/foo/bar/", "/foo/bar");

    (* Relative paths *)
    ("foo", cwd ^ "/foo");
    ("foo/bar", cwd ^ "/foo/bar");
    ("./foo", cwd ^ "/foo");

    (* Home directory *)
    ("~", home);
    ("~/", home);
    ("~/foo", home ^ "/foo");

    (* Parent directory *)
    ("..", parent_cwd);
    ("../", parent_cwd);
    ("../foo", parent_cwd ^ "/foo");

    (* Mixed navigation *)
    ("foo/..", cwd);
    ("foo/../bar", cwd ^ "/bar");
    ("foo/bar/..", cwd ^ "/foo");
    ("foo/./bar", cwd ^ "/foo/bar");

    (* Absolute with parent *)
    ("/foo/..", "/");
    ("/foo/bar/..", "/foo");
    ("/foo/../bar", "/bar");

    (* Edge cases *)
    ("//foo", "/foo");
    ("/foo//bar", "/foo/bar");
    ("///", "/");
    ("/./foo", "/foo");
    ("/..", "/");
    ("/../..", "/");
    ("/../foo", "/foo");
  ] in

  Printf.printf "Testing resolve_path:\n";
  let failed = ref false in

  List.iter (fun (input, expected) ->
    try
      let result = Cvfs.resolve_path input in
      if result = expected then
        Printf.printf "   %S\n" input
      else begin
        Printf.printf "   %S\n    Expected: %S\n    Got:      %S\n"
          input expected result;
        failed := true
      end
    with e ->
      Printf.printf "  =� %S\n    Exception: %s\n"
        input (Printexc.to_string e);
      failed := true
  ) test_cases;

  if !failed then
    (Printf.printf "\nL Some tests failed\n"; exit 1)
  else
    Printf.printf "\n All tests passed\n"

let test_project_path () =
  Printf.printf "\nTesting project_path (transformation only):\n";
  let home = Sys.getenv "HOME" in

  (* Just test the path transformation, not actual files *)
  let test_cases = [
    "/foo/bar";
    "/";
    ".";
    "~/project";
    "~/foo/bar/baz";
    "../parent";
  ] in

  List.iter (fun path ->
    let result = Cvfs.project_path path in
    let expected_prefix = home ^ "/.claude/projects/-" in
    if String.starts_with ~prefix:expected_prefix result then
      Printf.printf "  ✓ %S -> ...%s\n" path
        (String.sub result (String.length expected_prefix)
          (min 40 (String.length result - String.length expected_prefix)))
    else
      Printf.printf "  ✗ %S -> %S (unexpected format)\n" path result
  ) test_cases;

  Printf.printf "  (Manual verification needed - depends on system state)\n"

let () =
  test_resolve_path ();
  test_project_path ()