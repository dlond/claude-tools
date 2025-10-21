let print_short conversations =
  List.iter
    (fun c ->
      let time = Unix.gmtime c.Cvfs.timestamp in
      Printf.printf "%04d-%02d-%02d %02d:%02d  %s  %s\n" (time.tm_year + 1900)
        (time.tm_mon + 1) time.tm_mday time.tm_hour time.tm_min
        (String.sub c.id 0 8) c.summary)
    conversations

let print_long conversations =
  List.iter
    (fun c ->
      let time = Unix.gmtime c.Cvfs.timestamp in
      Printf.printf "%04d-%02d-%02d %02d:%02d:%02d  %s  %s  %s\n"
        (time.tm_year + 1900) (time.tm_mon + 1) time.tm_mday time.tm_hour
        time.tm_min time.tm_sec c.id c.path c.summary)
    conversations
