type state = {
  lex : Lexer.t;
  last_token : Token.t Located.t;
  errors : error list;
}

and error = Errors.t Located.t

type ('a, 'r) parser =
  state -> ('a -> state -> 'r) -> (error -> state -> 'r) -> 'r

let ( let* ) par f = fun st ok err -> par st (fun x s' -> (f x) s' ok err) err
let ( let+ ) par f = fun st ok err -> par st (fun x s' -> ok (f x) s') err
let ( <|> ) par1 par2 = fun st ok err -> par1 st ok (fun _ s' -> par2 st ok err)
let return x = fun st ok _ -> ok x st
let lookahead par = fun st ok err -> par st (fun x _ -> ok x st) err
let return_err e = fun st _ err -> err e { st with errors = e :: st.errors }
let emit_err e par = fun st -> par { st with errors = e :: st.errors }

let with_recovery recovery par =
 fun st ok err -> par st ok (fun e st' -> recovery e st' ok err)

let many par =
 fun st ok err ->
  let rec go acc st =
    let At (_, token), _ = Lexer.next_token st.lex in
    if token = Token.Eof then ok (List.rev acc) st
    else
      par st
        (fun x st' -> go (x :: acc) st')
        (fun _ st' -> ok (List.rev acc) st')
  in
  go [] st

let get_last_token = fun st ok err -> ok st.last_token st

let any_token =
 fun st ->
  let At (loc, token), lex' = Lexer.next_token st.lex in
  let st' = { st with lex = lex'; last_token = At (loc, token) } in
  match token with
  | Token.Error e -> return_err (Located.At (loc, e)) st'
  | _ -> return (Located.At (loc, token)) st'

let satisfy_map name f =
  let* (At (loc, token)) = lookahead any_token in
  match f token with
  | Some x ->
      let+ _ = any_token in
      Located.At (loc, x)
  | None ->
      let error =
        Errors.Expected { expected = name; actual = Token.to_string token }
      in
      return_err @@ Located.At (loc, error)

let expect token =
  satisfy_map (Token.to_string token) @@ function
  | x when x = token -> Some x
  | _ -> None

let synchronize =
  let rec go () =
    let* (At (_, token)) = lookahead any_token in
    match token with
    | Token.SemiColon | Token.Eof -> return ()
    | _ ->
        let* _ = any_token in
        go ()
  in
  go ()

let save_loc par =
  let* (At (loc, _)) = lookahead any_token in
  let+ x = par in
  Located.At (loc, x)

let parse_ident =
  satisfy_map "ident" (function Token.Ident id -> Some id | _ -> None)

let parse_number =
  satisfy_map "integer literal" (function
    | Token.Number n -> Some (Scanf.sscanf n "%Lu" Fun.id)
    | _ -> None)

let parse_binop =
  satisfy_map "binary operator" (function
    | Plus -> Some Syntax.AddOp
    | Minus -> Some Syntax.SubOp
    | Asterisk -> Some Syntax.MulOp
    | Slash -> Some Syntax.DivOp
    | _ -> None)

let recover_expr =
  with_recovery @@ fun error ->
  let+ _ = synchronize in
  Located.At (Located.get_loc error, Syntax.ErrorExpr error)

let parse_ident_expr =
  let+ parse_ident in
  Located.map (fun id -> Syntax.IdentExpr id) parse_ident

let parse_intlit_expr =
  let+ parse_number in
  Located.map (fun n -> Syntax.IntLitExpr n) parse_number

let rec parse_primary_expr () =
  let in_parens =
    let* _ = expect Token.LParen in
    let* expr = parse_expr () in
    let+ _ = expect Token.RParen in
    expr
  in
  recover_expr (parse_ident_expr <|> parse_intlit_expr <|> in_parens)

and parse_unary_expr () =
  (let* minus = expect Token.Minus in
   let+ rhs = parse_unary_expr () in
   Located.At (Located.get_loc minus, Syntax.UnaryOpExpr (Syntax.NegOp, rhs)))
  <|> parse_primary_expr ()

and parse_binop_expr prec =
  let* lhs = parse_unary_expr () in
  let rec loop lhs =
    (let* (Located.At (loc, binop)) = lookahead parse_binop in
     let next_prec = Syntax.binop_precedence binop in
     match next_prec with
     | x when x > prec ->
         let* _ = parse_binop in
         let* rhs = parse_binop_expr next_prec in
         loop (Located.At (loc, Syntax.BinOpExpr (binop, lhs, rhs)))
     | _ -> return lhs)
    <|> return lhs
  in
  loop lhs

and parse_expr () = recover_expr (parse_binop_expr 0)

let recover_stmt =
  with_recovery @@ fun error ->
  let+ _ = synchronize in
  Located.At (Located.get_loc error, Syntax.ErrorStmt error)

let missing_semi =
  let* (At (loc, token)) = get_last_token in
  let semicolon_loc = { loc with col = loc.col + Token.length token } in
  emit_err
    (At (semicolon_loc, Errors.MissingSemiColon))
    (return (Located.At (loc, Token.SemiColon)))

let parse_semi = expect Token.SemiColon <|> missing_semi

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

let parse_expr_stmt =
  let+ expr = parse_expr () in
  Located.At (Located.get_loc expr, Syntax.ExprStmt expr)

let parse_stmt =
  let* stmt =
    recover_stmt
      (parse_return_stmt <|> parse_decl_stmt <|> parse_assign_stmt
     <|> parse_expr_stmt)
  in
  let+ _ = parse_semi in
  stmt

let parse_t = many parse_stmt

let parse lex =
  let loc = Located.zero_location in
  let st = { lex; errors = []; last_token = At (loc, Token.Eof) } in
  let ast, st' =
    save_loc parse_t st
      (fun ast st' -> (ast, st'))
      (fun _ st' -> (Located.At(loc, []), st'))
  in
  let errors = List.rev st'.errors @ Sema.check_ast ast in
  ast, errors
