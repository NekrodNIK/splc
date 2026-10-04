let report_lexer (lex : Lexer.t) : Yojson.Basic.t * bool =
  let rec loop acc lex error_flag =
    let located_token, lex' = Lexer.next_token lex in
    let acc' = Located.to_json Token.to_json located_token :: acc in
    match located_token with
    | At (_, Eof) -> (acc', error_flag)
    | _ ->
        loop acc' lex'
          (* TODO: remove error_flag after implementing error collection in the parser stage *)
          (error_flag
          ||
          match located_token with
          | At (_, Token.Error _) -> true
          | _ -> false)
  in
  let l, f = loop [] lex false in
  (`List (List.rev l), f)

let report_parser (lex : Lexer.t) : Yojson.Basic.t * bool =
  let flag, ast = Parser.parse lex in
  Located.to_json (Syntax.to_json Fun.id) ast, flag
