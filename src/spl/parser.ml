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
let return_err e = fun st _ err -> err e { st with errors = e :: st.errors }
let lookahead par = fun st ok err -> par st (fun x _ -> ok x st) err

let emit_err e par =
 fun st ok err -> par { st with errors = e :: st.errors } ok err

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

let rec any_token () =
 fun st ->
  let At (loc, token), lex' = Lexer.next_token st.lex in
  let st' = { st with lex = lex'; last_token = At (loc, token) } in
  (match token with
  | Token.Error e -> return_err (Located.At (loc, e))
  | _ -> return (Located.At (loc, token)))
    st'

let satisfy_map name f =
  let* (At (loc, token)) = lookahead (any_token ()) in
  match f token with
  | Some x ->
      let* _ = any_token () in
      return (Located.At (loc, x))
  | None ->
      return_err
        (Located.At
           ( loc,
             Errors.Expected { expected = name; actual = Token.to_string token }
           ))

let expect token =
  satisfy_map (Token.to_string token) (fun x ->
      if x = token then Some token else None)

let rec synchronize () =
  let* (At (_, token)) = lookahead (any_token ()) in
  match token with
  | Token.SemiColon | Token.Eof -> return ()
  | _ ->
      let* _ = any_token () in
      synchronize ()

let save_loc p =
 fun st ok err ->
  let At (loc, _), _ = Lexer.next_token st.lex in
  p st (fun x st' -> ok (Located.At (loc, x)) st') err

let parse_ident =
  satisfy_map "ident" (function Token.Ident id -> Some id | _ -> None)

let parse_number =
  satisfy_map "integer literal" (function
    | Token.Number n -> Some n
    | _ -> None)

let parse_binop () =
  satisfy_map "binary operator" (function
    | Plus -> Some Syntax.AddOp
    | Minus -> Some Syntax.SubOp
    | Asterisk -> Some Syntax.MulOp
    | Slash -> Some Syntax.DivOp
    | _ -> None)

let parse_ident_expr =
  let+ (Located.At (loc, id)) = parse_ident in
  Located.At (loc, Syntax.IdentExpr id)

let parse_intlit_expr =
  let+ (Located.At (loc, n)) = parse_number in
  let n = try Scanf.sscanf n "%Lu" Fun.id with _ -> 0L in
  Located.At (loc, Syntax.IntLitExpr n)

let collect_error_expr =
  with_recovery (fun e ->
      let (Located.At (loc, _)) = e in
      let* _ = synchronize () in
      return (Located.At (loc, Syntax.ErrorExpr e)))

let rec parse_primary_expr () =
  collect_error_expr
    (parse_ident_expr <|> parse_intlit_expr
    <|> let* _ = expect Token.LParen in
        let* expr = parse_expr () in
        let+ _ = expect Token.RParen in
        expr)

and parse_unary_expr () =
  (let* (Located.At (loc, _)) = expect Token.Minus in
   let* rhs = parse_unary_expr () in
   return (Located.At (loc, Syntax.UnaryOpExpr (Syntax.NegOp, rhs))))
  <|> parse_primary_expr ()

and parse_binop_expr prec =
  let* lhs = parse_unary_expr () in
  let rec loop lhs =
    (let* (Located.At (loc, binop)) = lookahead (parse_binop ()) in
     let next_prec = Syntax.binop_precedence binop in
     if next_prec > prec then
       let* _ = parse_binop () in
       let* rhs = parse_binop_expr next_prec in
       loop (Located.At (loc, Syntax.BinOpExpr (binop, lhs, rhs)))
     else return lhs)
    <|> return lhs
  in
  loop lhs

and parse_expr () = collect_error_expr (parse_binop_expr 0)

let collect_error_stmt =
  with_recovery (fun e ->
      let (Located.At (loc, _)) = e in
      let* _ = synchronize () in
      return (Located.At (loc, Syntax.ErrorStmt e)))

let missing_semi =
  let* (At (loc, token)) = get_last_token in
  emit_err
    (At
       ({ loc with col = loc.col + Token.length token }, Errors.MissingSemiColon))
    (return @@ Located.At (loc, Token.SemiColon))

let parse_semi = expect Token.SemiColon <|> missing_semi

let parse_decl =
  let* (At (_, kw)) = expect Token.Val <|> expect Token.Var in
  let* id = parse_ident in
  let+ expr =
    collect_error_expr
      (let* _ = expect Token.Assign in
       parse_expr ())
  in
  Syntax.DeclStmt
    ((match kw with Token.Val -> Syntax.Val | _ -> Syntax.Var), id, expr)

let parse_return_stmt =
  save_loc
    (let* _ = expect Token.Return in
     let* e = parse_expr () in
     return (Syntax.ReturnStmt e))

let parse_decl_stmt =
  save_loc
    (let* _ = lookahead (expect Token.Var <|> expect Token.Val) in
     let* d = parse_decl in
     return d)

let parse_assign_stmt =
  let* (At (_, _) as id) = parse_ident in
  let* (At (loc, _)) = expect Token.Assign in
  let* expr = parse_expr () in
  return @@ Located.At (loc, Syntax.AssignStmt (id, expr))

let parse_expr_stmt =
  let* (At (loc, _) as e) = parse_expr () in
  return @@ Located.At (loc, Syntax.ExprStmt e)

let parse_stmt =
  let* stmt =
    collect_error_stmt
      (parse_return_stmt <|> parse_decl_stmt <|> parse_assign_stmt
     <|> parse_expr_stmt)
  in
  let+ _ = parse_semi in
  stmt

let parse lex =
  let st, res =
    (save_loc (many parse_stmt))
      {
        lex;
        errors = [];
        last_token = At ({ offset = 0; col = 1; line = 1 }, Token.Eof);
      }
      (fun tree s -> (s, tree))
      (fun _ s ->
        (s, Located.map (fun _ -> []) (fst @@ Lexer.next_token s.lex)))
  in
  (res, List.rev st.errors @ Sema.check_ast @@ Located.get res)
