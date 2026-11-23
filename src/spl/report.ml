module TokenReport = struct
  type node = { line : int; column : int; kind : string; value : string }
  [@@deriving yojson]

  let to_json (Located.At (loc, (token : Token.t))) =
    let kind =
      match token with
      | Ident _ -> "IDENT"
      | NumberLiteral _ -> "INT"
      | StringLiteral _ -> "STR"
      | True -> "TRUE"
      | False -> "FALSE"
      | Val -> "VAL"
      | Var -> "VAR"
      | Return -> "RETURN"
      | If -> "IF"
      | Else -> "ELSE"
      | While -> "WHILE"
      | Break -> "BREAK"
      | Continue -> "CONTINUE"
      | LParen -> "LPAREN"
      | RParen -> "RPAREN"
      | LBrace -> "LBRACE"
      | RBrace -> "RBRACE"
      | Semi -> "SEMI"
      | Colon -> "COLON"
      | Comma -> "COMMA"
      | Assign -> "ASSIGN"
      | Plus -> "PLUS"
      | Minus -> "MINUS"
      | Star -> "MULT"
      | Slash -> "DIV"
      | And -> "AND"
      | Or -> "OR"
      | Eq -> "EQ"
      | Ne -> "NE"
      | Lt -> "LT"
      | Le -> "LE"
      | Gt -> "GT"
      | Ge -> "GE"
      | Not -> "NOT"
      | Extern -> "EXTERN"
      | Def -> "DEF"
      | Cast -> "CAST"
      (* *)
      | Int8 -> "INT8"
      | Int16 -> "INT16"
      | Int32 -> "INT32"
      | Int64 -> "INT64"
      | Bool -> "BOOL"
      | Void -> "VOID"
      | String -> "STRING"
      (* *)
      | Error _ -> "ERROR"
      | Eof -> "EOF"
    in
    { line = loc.line; column = loc.col; kind; value = Token.to_string token }
    |> node_to_yojson
    |> Yojson.Safe.to_basic
end

module SyntaxReport (Id : sig
  type t

  val to_string : t -> string
end) =
struct
  type node = {
    line : int;
    column : int;
    kind : string;
    type_ : string option; [@yojson.default None] [@yojson.name "type"]
    mut : string option; [@yojson.default None]
    value : string option; [@yojson.default None]
    elems : node list;
  }
  [@@deriving yojson, make]

  let error_to_node (Located.At (loc, err)) =
    make_node ~kind:"Error" ~line:loc.line ~column:loc.col
      ~value:(Errors.to_string err) ()

  let ident_to_node (Located.At (loc, id)) =
    make_node ~kind:"Ident" ~line:loc.line ~column:loc.col
      ~value:(Id.to_string id) ()

  let rec expr_to_node (Located.At (loc, expr)) =
    let make_node = make_node ~line:loc.line ~column:loc.col in
    match expr with
    | Syntax.BinOpExpr (op, lhs, rhs) ->
        make_node ~kind:"BinOp"
          ~elems:[ expr_to_node lhs; expr_to_node rhs ]
          ~value:(Syntax.binop_to_string op)
          ()
    | Syntax.UnaryOpExpr (op, expr) ->
        make_node ~kind:"Unary"
          ~elems:[ expr_to_node expr ]
          ~value:(Syntax.unop_to_string op) ()
    | Syntax.IdentExpr id -> make_node ~kind:"Ident" ~value:(Id.to_string id) ()
    | Syntax.StringLitExpr str -> make_node ~kind:"StringLiteral" ~value:str ()
    | Syntax.IntLitExpr n ->
        make_node ~kind:"IntLiteral" ~value:(Printf.sprintf "%Lu" n) ()
    | Syntax.BoolLitExpr v ->
        make_node ~kind:"BoolLiteral" ~value:(Bool.to_string v) ()
    | Syntax.CallExpr (callee, args) ->
        make_node ~kind:"Call"
          ~elems:(expr_to_node callee :: List.map expr_to_node args)
          ()
    | Syntax.CastExpr (Located.At (_, type_), arg) ->
        (* TODO: add type_ field report *)
        make_node ~kind:"Cast" ~elems:[ expr_to_node arg ] ()
    | Syntax.ErrorExpr err -> error_to_node err

  let rec stmt_to_node (Located.At (loc, stmt)) =
    let make_node = make_node ~line:loc.line ~column:loc.col in
    match stmt with
    | Syntax.ExprStmt expr -> expr_to_node expr
    | Syntax.ReturnStmt expr ->
        make_node ~kind:"Return" ~elems:[ expr_to_node expr ] ()
    | Syntax.DeclStmt (mut, id, type_, expr) ->
        (* TODO: add type_ field report *)
        make_node ~kind:"Declare"
          ~elems:[ ident_to_node id; expr_to_node expr ]
          ~mut:(Syntax.mut_to_string mut) ()
    | Syntax.AssignStmt (id, expr) ->
        make_node ~kind:"Assign"
          ~elems:[ ident_to_node id; expr_to_node expr ]
          ()
    | Syntax.IfStmt (cond, then_, Some else_) ->
        make_node ~kind:"If"
          ~elems:[ expr_to_node cond; stmt_to_node then_; stmt_to_node else_ ]
          ()
    | Syntax.IfStmt (cond, then_, None) ->
        make_node ~kind:"If" ~elems:[ expr_to_node cond; stmt_to_node then_ ] ()
    | Syntax.WhileStmt (cond, body) ->
        make_node ~kind:"While"
          ~elems:[ expr_to_node cond; stmt_to_node body ]
          ()
    | Syntax.BreakStmt -> make_node ~kind:"Break" ()
    | Syntax.ContinueStmt -> make_node ~kind:"Continue" ()
    | Syntax.BlockStmt stmts ->
        make_node ~kind:"Block" ~elems:(List.map stmt_to_node stmts) ()
    | Syntax.ErrorStmt err -> error_to_node err

  let param_to_node (Located.At (loc, Syntax.Param (id, _))) =
    make_node ~line:loc.line ~column:loc.col ~kind:"Param"
      ~elems:[ ident_to_node id ]
      ()

  let top_decl_to_node (Located.At (loc, top_decl)) =
    let make_node = make_node ~line:loc.line ~column:loc.col in
    match top_decl with
    | Syntax.ExternTopDecl (id, params, return_type) ->
        (* TODO: add return_type field report *)
        make_node ~kind:"ExternDecl"
          ~elems:(ident_to_node id :: List.map param_to_node params)
          ()
    | Syntax.FuncTopDecl (id, params, return_type, body) ->
        (* TODO: add return_type field report *)
        make_node ~kind:"FuncDecl"
          ~elems:
            ((ident_to_node id :: List.map param_to_node params)
            @ [ stmt_to_node body ])
          ()

  let ast_to_node (Located.At (loc, ast)) =
    make_node ~line:loc.line ~column:loc.col ~kind:"Program"
      ~elems:(List.map top_decl_to_node ast)
      ()

  let ast_to_json ast =
    ast_to_node ast |> node_to_yojson |> Yojson.Safe.to_basic
end

let report_lexer (lex : Lexer.t) : Yojson.Basic.t * bool =
  let rec loop acc lex error_flag =
    let token, lex' = Lexer.next_token lex in
    let acc' = TokenReport.to_json token :: acc in
    match token with
    | At (_, Eof) -> (acc', error_flag)
    | _ ->
        loop acc' lex'
          (error_flag
          || match token with At (_, Token.Error _) -> true | _ -> false)
  in
  let l, f = loop [] lex false in
  (`List (List.rev l), f)

module SyntaxReport_ = SyntaxReport (struct
  type t = string

  let to_string = Fun.id
end)

let report_ast (ast : 'id Syntax.t Located.t) : Yojson.Basic.t =
  SyntaxReport_.ast_to_json ast
