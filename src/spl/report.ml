let report_lexer (lex : Lexer.t) : Yojson.Basic.t =
  let rec loop acc lex =
    let lex', located_token = Lexer.next_token lex in
    let acc' = Located.to_json Token.to_json located_token :: acc in
    match located_token with At (Eof, _) -> acc' | _ -> loop acc' lex'
  in
  `List (List.rev @@ loop [] lex)
