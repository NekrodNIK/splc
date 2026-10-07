(* TODO: refactor it *)
module SyntaxReport = struct
  let pack_node ?(comment = "") kind elems =
    let node = [ ("kind", `String kind); ("elems", `List elems) ] in
    `Assoc
      (match comment with
      | "" -> node
      | _ -> node @ [ ("comment", `String comment) ])

  let lid_to_json f =
    Located.to_json (fun id -> pack_node "Ident" [] ~comment:(f id))

  let lerror_to_json =
    Located.to_json (fun err ->
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

  and lexpr_to_json id_to_str = expr_to_json id_to_str |> Located.to_json

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

  let to_json id_to_str (ast : 'id Syntax.t) =
    pack_node "Program"
      (List.map (Located.to_json (stmt_to_json id_to_str)) ast)
end

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
  (Located.to_json (SyntaxReport.to_json Fun.id) ast, flag)
