(* TODO: refactor it *)

type state = { lex : Lexer.t; is_err : bool }
type error = Errors.t Located.t

type ('a, 'r) parser =
  state -> ('a -> state -> 'r) -> (error -> state -> 'r) -> 'r

let ( let* ) par f = fun st ok err -> par st (fun x s' -> (f x) s' ok err) err
let ( let+ ) par f = fun st ok err -> par st (fun x s' -> ok (f x) s') err
let ( <|> ) par1 par2 = fun st ok err -> par1 st ok (fun _ s' -> par2 st ok err)
let return x = fun st ok _ -> ok x st
let return_err e = fun st _ err -> err e { st with is_err = true }
let lookahead par = fun st ok err -> par st (fun x _ -> ok x st) err

let many par =
 fun st ok err ->
  let rec go acc s =
    let At (_, tok), _ = Lexer.next_token s.lex in
    if tok = Token.Eof then ok (List.rev acc) s
    else par s (fun x s' -> go (x :: acc) s') (fun _ s' -> ok (List.rev acc) s')
  in
  go [] st

let any_token =
 fun st ok err ->
  let token, lex' = Lexer.next_token st.lex in
  ok token { st with lex = lex' }

let satisfy_map f =
  let* (At (loc, token)) = any_token in
  match f token with
  | Some x -> return (Located.At (loc, x))
  | None ->
      return_err
        (Located.At (loc, Errors.UnexpectedToken (Token.to_string token)))

let expect token = satisfy_map (fun x -> if x = token then Some token else None)

let rec synchronize () =
  let* (At (_, token)) = any_token in
  match token with
  | Token.SemiColon | Token.Eof -> return ()
  | _ -> synchronize ()

let save_loc p =
 fun st ok err ->
  let At (loc, _), _ = Lexer.next_token st.lex in
  p st (fun x st' -> ok (Located.At (loc, x)) st') err

let error_stub con =
  let* (At (loc, _)) = lookahead any_token in
  let* _ = synchronize () in
  return (Located.At (loc, con (Located.At (loc, Errors.Stub))))

let parse_ident = satisfy_map (function Token.Ident id -> Some id | _ -> None)
let parse_number = satisfy_map (function Token.Number n -> Some n | _ -> None)

let parse_binop () =
  satisfy_map (function
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

let rec parse_primary_expr () =
  parse_ident_expr <|> parse_intlit_expr
  <|> let* _ = expect Token.LParen in
      let* expr = parse_expr () in
      (let+ _ = expect Token.RParen in
       expr)
      <|> error_stub (fun x -> Syntax.ErrorExpr x)

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

and parse_expr () =
  parse_binop_expr 0 <|> error_stub (fun x -> Syntax.ErrorExpr x)

let missing_semi =
  let* (At (loc, _)) = lookahead any_token in
  fun st ok _ ->
    ok (Located.At (loc, Token.SemiColon)) { st with is_err = true }

let parse_semi = expect Token.SemiColon <|> missing_semi

let parse_decl =
  let* (At (_, kw)) = expect Token.Val <|> expect Token.Var in
  let* id = parse_ident in
  let+ expr =
    (let* _ = expect Token.Assign in
     parse_expr ())
    <|> error_stub (fun x -> Syntax.ErrorExpr x)
  in
  Syntax.DeclStmt
    ((match kw with Token.Val -> Syntax.Val | _ -> Syntax.Var), id, expr)

let parse_return_stmt =
  save_loc
    (let* _ = expect Token.Return in
     let* e = parse_expr () in
     let* _ = parse_semi in
     return (Syntax.ReturnStmt e))

let parse_decl_stmt =
  save_loc
    (let* _ = lookahead (expect Token.Var <|> expect Token.Val) in
     let* d = parse_decl in
     let* _ = parse_semi in
     return d)

let parse_assign_stmt =
  let* (At (_, _) as id) = parse_ident in
  let* (At (loc, _)) = expect Token.Assign in
  let* expr = parse_expr () in
  let* _ = parse_semi in
  return (Located.At (loc, Syntax.AssignStmt (id, expr)))

let parse_expr_stmt =
  let* (At (loc, _) as e) = parse_expr () in
  let* _ = parse_semi in
  fun s ok _ ->
    ok (Located.At (loc, Syntax.ExprStmt e)) { s with is_err = true }

let parse_stmt =
  parse_return_stmt <|> parse_decl_stmt <|> parse_assign_stmt
  <|> parse_expr_stmt
  <|> error_stub (fun x -> Syntax.ErrorStmt x)

let parse lex : bool * string Syntax.t Located.t =
  let st, res =
    (save_loc (many parse_stmt))
      { lex; is_err = false }
      (fun tree s -> (s, tree))
      (fun _ s ->
        (s, Located.map (fun _ -> []) (fst @@ Lexer.next_token s.lex)))
  in
  (st.is_err || (Sema.check_ast @@ Located.get res), res)
