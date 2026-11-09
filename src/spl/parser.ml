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
    register_err error (return (Located.At (loc, Syntax.ErrorExpr error)))
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

let rec parse_call_args () =
  let* (At (loc, _)) = expect LParen in
  let* params =
    sep_by
      (let* _ = not_followed_by (expect RParen) in
       parse_expr ())
      (expect Comma)
  in
  let+ _ = expect RParen in
  Located.At (loc, params)

and parse_call_expr () =
  let* primary_expr = parse_primary_expr () in
  (let+ (At (loc, args)) = parse_call_args () in
   Located.At (loc, Syntax.CallExpr (primary_expr, args)))
  <|> return primary_expr

and parse_primary_expr () =
  let in_parens =
    let* _ = expect Token.LParen in
    let* expr = parse_expr () in
    let+ _ = expect Token.RParen in
    expr
  in
  recover_expr
    (parse_ident_expr <|> parse_intlit_expr <|> parse_boollit_expr <|> in_parens)

and parse_unop_expr () =
  (let* (At (loc, unop)) = parse_unop in
   let+ rhs = parse_unop_expr () in
   Located.At (loc, Syntax.UnaryOpExpr (unop, rhs)))
  <|> parse_call_expr ()

and parse_binop_expr prec =
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

  let* lhs = parse_unop_expr () in
  loop lhs

and parse_expr () = parse_binop_expr (Syntax.binop_min_precedence - 1)

let recover_stmt =
  let recovery (Located.At (loc, _) as error) =
    register_err error (return (Located.At (loc, Syntax.ErrorStmt error)))
  in
  with_recovery recovery

let parse_expr_stmt =
  let+ (Located.At (loc, _) as expr) = parse_expr () in
  Located.At (loc, Syntax.ExprStmt expr)

let missing_semi =
  let* (At (loc, token)) = get_last_token in
  let semicolon_loc = { loc with col = loc.col + Token.length token } in
  register_err
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
  let+ (At (loc, _)) = expect Break in
  Located.At (loc, Syntax.BreakStmt)

let parse_cond =
  let* cond, has_errors =
    (let* _ = expect Token.LParen in
     let* cond = parse_expr () in
     let+ _ = expect Token.RParen in
     cond)
    |> recover_expr
    |> has_errors
  in
  let* _ =
    if has_errors then synchronize [ Token.RParen; Token.LBrace; Token.Semi ]
    else return ()
  in
  return cond

let rec parse_stmt () =
  let* _ = not_followed_by (expect Token.RBrace) in
  parse_block_stmt ()
  <|> parse_cond_stmt ()
  <|> parse_while_stmt ()
  <|> (let* stmt, has_errors =
         parse_continue_stmt
         <|> parse_break_stmt
         <|> parse_return_stmt
         <|> parse_decl_stmt
         <|> try_ parse_assign_stmt
         <|> parse_expr_stmt
         |> recover_stmt
         |> has_errors
       in
       let* _ = if has_errors then synchronize [ Token.Semi ] else return () in
       let+ _ = parse_semi in
       stmt)
  |> recover_stmt

and parse_block_stmt () =
  let* (At (loc, _)) = expect Token.LBrace in
  let* stmts = many (parse_stmt ()) in
  let+ _ = expect Token.RBrace in
  Located.At (loc, Syntax.BlockStmt stmts)

and parse_cond_stmt () =
  let* (At (loc, _)) = expect Token.If in
  let* cond = parse_cond in
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
  let* cond = parse_cond in
  let+ stmt = parse_stmt () in
  Located.At (loc, Syntax.WhileStmt (cond, stmt))

let parse_params =
  let* _ = expect LParen in
  let* params = sep_by parse_ident (expect Comma) in
  let+ _ = expect RParen in
  params

let parse_extern_top_decl =
  let* (At (loc, _)) = expect Token.Extern in
  let* _ = expect Token.Def in
  let* fun_ident = parse_ident in
  let* params = parse_params in
  let+ _ = expect Semi in
  Located.At (loc, Syntax.ExternTopDecl (fun_ident, params))

let parse_fun_top_decl =
  let* (At (loc, _)) = expect Token.Def in
  let* fun_ident = parse_ident in
  let* params = parse_params in
  let+ stmt = parse_stmt () in
  Located.At (loc, Syntax.FuncTopDecl (fun_ident, params, stmt))

let parse_top_decl = parse_extern_top_decl <|> parse_fun_top_decl
let parse_t = many parse_top_decl

let parse lex =
  let state = make_initial_state lex in
  let ast, errors = run_parser parse_t state in
  (ast, errors @ Sema.check_ast ast)
