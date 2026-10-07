let located_to_json inner_to_json (loc : 'a Located.t) =
  let (At (loc, inner)) = loc in
  Yojson.Basic.Util.combine (inner_to_json inner)
  @@ `Assoc [ ("line", `Int loc.line); ("column", `Int loc.col) ]

module TokenReport = struct
  let to_json (token : Token.t) : Yojson.Basic.t =
    let kind =
      match token with
      | Ident _ -> "IDENT"
      | Number _ -> "INT"
      | Val -> "VAL"
      | Var -> "VAR"
      | Assign -> "ASSIGN"
      | Return -> "RETURN"
      | Plus -> "PLUS"
      | Minus -> "MINUS"
      | Slash -> "DIV"
      | Asterisk -> "MULT"
      | SemiColon -> "SEMI"
      | LParen -> "LPAREN"
      | RParen -> "RPAREN"
      | Error err -> "ERROR"
      | Eof -> "EOF"
    in
    `Assoc
      [ ("kind", `String kind); ("value", `String (Token.to_string token)) ]
end

module SyntaxReport = struct
  let pack_node ?(comment = "") kind elems =
    let node = [ ("kind", `String kind); ("elems", `List elems) ] in
    `Assoc
      (match comment with
      | "" -> node
      | _ -> node @ [ ("comment", `String comment) ])

  let lid_to_json f =
    located_to_json (fun id -> pack_node "Ident" [] ~comment:(f id))

  let lerror_to_json =
    located_to_json (fun err ->
        pack_node "Error" [] ~comment:(Errors.to_string err))

  let rec expr_to_json id_to_str (expr : 'id Syntax.expr) =
    match expr with
    | BinOpExpr (op, lhs, rhs) ->
        pack_node "BinOp"
          [ lexpr_to_json id_to_str lhs; lexpr_to_json id_to_str rhs ]
          ~comment:(Syntax.binop_to_string op)
    | UnaryOpExpr (op, expr) ->
        pack_node "Unary"
          [ lexpr_to_json id_to_str expr ]
          ~comment:(Syntax.unop_to_string op)
    | IdentExpr id -> pack_node "Ident" [] ~comment:(id_to_str id)
    | IntLitExpr n -> pack_node "IntLiteral" [] ~comment:(Int64.to_string n)
    | ErrorExpr err -> lerror_to_json err

  and stmt_to_json id_to_str (stmt : 'id Syntax.stmt) =
    match stmt with
    | ExprStmt lexpr -> lexpr_to_json id_to_str lexpr
    | ReturnStmt lexpr -> pack_node "Return" [ lexpr_to_json id_to_str lexpr ]
    | DeclStmt (mut, lid, lexpr) ->
        pack_node "Declare"
          [ lid_to_json id_to_str lid; lexpr_to_json id_to_str lexpr ]
          ~comment:(Syntax.mut_to_string mut)
    | AssignStmt (lid, lexpr) ->
        pack_node "Assign"
          [ lid_to_json id_to_str lid; lexpr_to_json id_to_str lexpr ]
    | ErrorStmt err -> lerror_to_json err

  and lexpr_to_json f = located_to_json (expr_to_json f)
  and lstmt_to_json f = located_to_json (stmt_to_json f)

  let to_json id_to_str (ast : 'id Syntax.t) =
    pack_node "Program" (List.map (lstmt_to_json id_to_str) ast)
end

let report_lexer (lex : Lexer.t) : Yojson.Basic.t * bool =
  let rec loop acc lex error_flag =
    let located_token, lex' = Lexer.next_token lex in
    let acc' = located_to_json TokenReport.to_json located_token :: acc in
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
  (located_to_json (SyntaxReport.to_json Fun.id) ast, flag)
