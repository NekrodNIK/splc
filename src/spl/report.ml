let report_lexer (lex : Lexer.t) : Yojson.Basic.t * bool =
  let rec loop acc lex error_flag =
    let lex', located_token = Lexer.next_token lex in
    let acc' = Located.to_json Token.to_json located_token :: acc in
    match located_token with
    | At (Eof, _) -> (acc', error_flag)
    | _ ->
        loop acc' lex'
          (* TODO: remove error_flag after implementing error collection in the parser stage *)
          (error_flag
          ||
          match located_token with
          | At (Token.Error _, _) -> true
          | _ -> false)
  in
  let l, f = loop [] lex false in
  (`List (List.rev l), f)
