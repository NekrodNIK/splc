open Parser_base

let parse_ident =
  satisfy_map "ident" (function Ident id -> Some id | _ -> None)

let parse_binop =
  satisfy_map "binary operator" @@ function
  | Plus -> Some Syntax.AddOp
  | Minus -> Some Syntax.SubOp
  | Star -> Some Syntax.MulOp
  | Slash -> Some Syntax.DivOp
  | And -> Some Syntax.AndOp
  | Or -> Some Syntax.OrOp
  | Lt -> Some Syntax.LtOp
  | Le -> Some Syntax.LeOp
  | Gt -> Some Syntax.GtOp
  | Ge -> Some Syntax.GeOp
  | Eq -> Some Syntax.EqOp
  | Ne -> Some Syntax.NeOp
  | _ -> None

let parse_unop =
  satisfy_map "unary operator" @@ function
  | Minus -> Some Syntax.NegOp
  | Not -> Some Syntax.NotOp
  | _ -> None

let recover_expr =
  let recovery (Located.At (loc, _) as error) =
    emit_err error (return (Located.At (loc, Syntax.ErrorExpr error)))
  in
  with_recovery recovery

let parse_ident_expr =
  let+ parse_ident in
  Located.map (fun id -> Syntax.IdentExpr id) parse_ident

let parse_intlit_expr =
  satisfy_map "integer literal" @@ function
  | Number s ->
      Option.map
        (fun n -> Syntax.IntLitExpr n)
        (Scanf.sscanf_opt s "%Lu" Fun.id)
  | _ -> None

let parse_boollit_expr =
  satisfy_map "boolean literal" @@ function
  | True -> Some (Syntax.BoolLitExpr true)
  | False -> Some (Syntax.BoolLitExpr false)
  | _ -> None

let rec parse_primary_expr () =
  let in_parens =
    let* _ = expect Token.LParen in
    let* expr = parse_expr () in
    let+ _ = expect Token.RParen in
    expr
  in
  recover_expr (parse_ident_expr <|> parse_intlit_expr <|> in_parens)

and parse_unop_expr () =
  begin
    let* (At (loc, unop)) = parse_unop in
    let+ rhs = parse_unop_expr () in
    Located.At (loc, Syntax.UnaryOpExpr (unop, rhs))
  end
  <|> parse_primary_expr ()

and parse_binop_expr prec =
  let* lhs = parse_unop_expr () in
  let rec loop lhs =
    begin
      let* (Located.At (loc, binop)) = lookahead parse_binop in
      let next_prec = Syntax.binop_precedence binop in

      match next_prec with
      | x when x > prec ->
          let* _ = parse_binop in
          let* rhs = parse_binop_expr next_prec in
          loop (Located.At (loc, Syntax.BinOpExpr (binop, lhs, rhs)))
      | _ -> return lhs
    end
    <|> return lhs
  in
  loop lhs

and parse_expr () = parse_binop_expr (Syntax.binop_min_precedence - 1)

let recover_stmt =
  let recovery (Located.At (loc, _) as error) =
    emit_err error (return (Located.At (loc, Syntax.ErrorStmt error)))
  in
  with_recovery recovery

let parse_expr_stmt =
  let+ expr = parse_expr () in
  Located.At (Located.get_loc expr, Syntax.ExprStmt expr)

let missing_semi =
  let* (At (loc, token)) = get_last_token in
  let semicolon_loc = { loc with col = loc.col + Token.length token } in
  emit_err
    (At (semicolon_loc, Errors.MissingSemi))
    (return (Located.At (loc, Token.Semi)))

let parse_semi = expect Token.Semi <|> missing_semi

let parse_decl_stmt =
  let* (At (loc, mut)) =
    satisfy_map "mutability keyword" (function
      | Token.Val -> Some Syntax.Val
      | Token.Var -> Some Syntax.Var
      | _ -> None)
  in
  let* id = parse_ident in
  let+ expr =
    recover_expr
      (let* _ = expect Token.Assign in
       parse_expr ())
  in
  Located.At (loc, Syntax.DeclStmt (mut, id, expr))

let parse_return_stmt =
  let* (At (loc, _)) = expect Token.Return in
  let+ expr = parse_expr () in
  Located.At (loc, Syntax.ReturnStmt expr)

let parse_assign_stmt =
  let* id = parse_ident in
  let* (At (loc, _)) = expect Token.Assign in
  let+ expr = parse_expr () in
  Located.At (loc, Syntax.AssignStmt (id, expr))

let parse_continue_stmt =
  let+ (At (loc, _)) = expect Continue in
  Located.At (loc, Syntax.ContinueStmt)

let parse_break_stmt =
  let+ (At (loc, _)) = expect Continue in
  Located.At (loc, Syntax.BreakStmt)

let rec parse_stmt () =
  let* _ = not_followed_by (expect Token.RBrace) in
  parse_block_stmt ()
  <|> parse_cond_stmt ()
  <|> parse_while_stmt ()
  <|> (let* stmt =
         parse_continue_stmt
         <|> parse_break_stmt
         <|> parse_return_stmt
         <|> parse_decl_stmt
         <|> try_ parse_assign_stmt
         <|> parse_expr_stmt
         |> recover_stmt
       in
       let* has_error = clr_has_error has_error in
       let* _ = if has_error then synchronize [ Token.Semi ] else return () in
       let+ _ = parse_semi in
       stmt)
  |> recover_stmt

and parse_block_stmt () =
  let* (At (loc, _)) = expect Token.LBrace in
  let* stmts = parse_t () in
  let+ _ = expect Token.RBrace in
  Located.At (loc, Syntax.BlockStmt stmts)

and synchronize_cond =
  let rec go () =
    let* (At (_, token)) = lookahead any_token in
    match token with
    | Token.RParen | Token.LBrace | Token.Semi | Token.Eof -> return ()
    | _ ->
        let* _ = any_token in
        go ()
  in
  go ()

and recover_cond_expr () =
  with_recovery @@ fun error ->
  emit_err error
  @@
  let+ _ = synchronize_cond in
  Located.At (Located.get_loc error, Syntax.ErrorExpr error)

and parse_cond_stmt () =
  let* (At (loc, _)) = expect Token.If in
  let* cond =
    recover_expr
      (let* _ = expect Token.LParen in
       let* cond = parse_expr () in
       let+ _ = expect Token.RParen in
       cond)
  in
  let* has_error = clr_has_error has_error in
  let* _ = if has_error then synchronize [ Token.RParen; Token.LBrace ] else return () in
  let* then_stmt = parse_stmt () in

  let+ else_stmt =
    (let* _ = expect Token.Else in
     let+ stmt = parse_stmt () in
     Some stmt)
    <|> return None
  in

  Located.At (loc, Syntax.IfStmt (cond, then_stmt, else_stmt))

and parse_while_stmt () =
  let* (At (loc, _)) = expect Token.While in
  let* cond =
    recover_cond_expr ()
      (let* _ = expect Token.LParen in
       let* cond = parse_expr () in
       let+ _ = expect Token.RParen in
       cond)
  in
  let+ stmt = parse_stmt () in
  Located.At (loc, Syntax.WhileStmt (cond, stmt))

and parse_t () = many (parse_stmt ())

let parse lex =
  let state = make_initial_state lex in
  let ast, errors = run_parser (parse_t ()) state in
  (ast, errors @ Sema.check_ast ast)
