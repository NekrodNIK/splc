type error = Errors.t Located.t
type stream = Lexer.t
type output = string Syntax.t

type 'a t = {
  run : 'r. stream -> ('a -> stream -> 'r) -> (error -> stream -> 'r) -> 'r;
}

let ( <|> ) (p1 : 'a t) (p2 : 'a t) : 'a t =
  { run = (fun s ok err -> p1.run s ok (fun _ _ -> p2.run s ok err)) }

let ( let* ) (p : 'a t) (f : 'a -> 'b t) : 'b t =
  { run = (fun s ok err -> p.run s (fun x s' -> (f x).run s' ok err) err) }

let return x = { run = (fun s ok err -> ok x s) }
let return_err e = { run = (fun s ok err -> err e s) }

let map (f : 'a -> 'b) (p : 'a t) : 'b t =
  { run = (fun s ok err -> p.run s (fun x s' -> ok (f x) s') err) }

let ( let+ ) p f = map f p

let save_loc p =
  {
    run =
      (fun s ok err ->
        p.run s
          (fun x s' ->
            ok (Located.map (fun _ -> x) (fst @@ Lexer.next_token s)) s')
          err);
  }

let lookahead p = { run = (fun s ok err -> p.run s (fun x _ -> ok x s) err) }

let any_token =
  { run = (fun s ok err -> match Lexer.next_token s with x, s' -> ok x s') }

let parse_error f p =
  { run = (fun s ok err -> p.run s ok (fun e s' -> ok (f e) s')) }

let satisfy_map (f : Token.t -> 'a option) =
  let* (At (loc, token)) = any_token in
  match f token with
  | Some x -> return (Located.At (loc, x))
  | None ->
      return_err
        (Located.At (loc, Errors.UnexpectedToken (Token.to_string token)))

let satisfy f = satisfy_map (fun x -> if f x then Some () else None)

let many (p : 'a t) : 'a list t =
  {
    run =
      (fun s ok err ->
        let rec go acc s =
          p.run s
            (fun x s' -> go (x :: acc) s')
            (fun e s' -> ok (List.rev acc) s)
        in
        go [] s);
  }

let parse_ident = satisfy_map (function Token.Ident id -> Some id | _ -> None)

let parse_number =
  satisfy_map (function
    | Token.Number n -> Some (Int64.of_string n)
    | _ -> None)

let parse_ident_expr = map (fun id -> Syntax.IdentExpr id) parse_ident
let parse_intlit_expr = map (fun n -> Syntax.IntLitExpr n) parse_number

let rec parse_primary_expr () =
  let lparen = satisfy (( = ) Token.LParen) in
  let rparen = satisfy (( = ) Token.RParen) in
  parse_ident_expr <|> parse_intlit_expr
  <|> let* _ = lparen in
      let* expr = parse_primary_expr () in
      let* _ = rparen in
      return expr

let parse_binop =
  satisfy_map (function
    | Token.Plus -> Some Syntax.Add
    | Token.Minus -> Some Syntax.Sub
    | Token.Asterisk -> Some Syntax.Mul
    | Token.Slash -> Some Syntax.Div
    | _ -> None)

let rec parse_binop_expr level =
  let* lhs = save_loc (parse_primary_expr ()) in
  let rec go lhs =
    let* (At (_, binop)) = lookahead parse_binop in
    let precedence = Syntax.binop_precedence binop in
    if precedence > level then
      let* (At (loc, binop)) = parse_binop in
      let* rhs = parse_binop_expr precedence in
      go
      @@ Located.map (fun _ -> Syntax.BinOpExpr (lhs, At (loc, binop), rhs)) lhs
    else return lhs
  in
  go lhs

let parse_expr = parse_binop_expr (Syntax.binop_precedence Syntax.Add)

let parse_val_decl =
  let* _ = satisfy (( = ) Token.Val) in
  let* id = parse_ident in
  let* _ = satisfy (( = ) Token.Assign) in
  let* expr = parse_expr in
  return (Syntax.ValDecl (id, expr))

let parse_var_decl =
  let* _ = satisfy (( = ) Token.Var) in
  let* id = parse_ident in
  let* _ = satisfy (( = ) Token.Assign) in
  let* expr = parse_expr in
  return (Syntax.VarDecl (id, expr))

let parse_decl = parse_val_decl <|> parse_var_decl

let parse_return_stmt =
  let* _ = satisfy (( = ) Token.Return) in
  let* expr = parse_expr in
  let* _ = satisfy (( = ) Token.SemiColon) in
  return (Syntax.ReturnStmt expr)

let parse_decl_stmt =
  let* decl = save_loc parse_decl in
  let* _ = satisfy (( = ) Token.SemiColon) in
  return (Syntax.DeclStmt decl)

let parse_assign_stmt =
  let* id = parse_ident in
  let* _ = satisfy (( = ) Token.Assign) in
  let* expr = parse_expr in
  let* _ = satisfy (( = ) Token.SemiColon) in
  return (Syntax.AssignStmt (id, expr))

let parse_expr_stmt =
  let* expr = parse_expr in
  let* _ = satisfy (( = ) Token.SemiColon) in
  return (Syntax.ExprStmt expr)

let parse_error_stmt = parse_error (fun x -> Syntax.ErrorStmt x)

let parse_stmt =
  let p =
    parse_return_stmt <|> parse_decl_stmt <|> parse_assign_stmt
    <|> parse_expr_stmt
  in
  save_loc @@ parse_error_stmt p

let parse_t = save_loc (many parse_stmt)

let parse lex : string Syntax.t Located.t =
  parse_t.run lex
    (fun tree _ -> tree)
    (fun _ s -> Located.map (fun _ -> []) (fst @@ Lexer.next_token s))
