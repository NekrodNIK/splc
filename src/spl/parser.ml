(* FIXME: refactor it *)

type state = { lex : Lexer.t; is_err : bool }
type error = Errors.t Located.t

type 'a parser = {
  run : 'r. state -> ('a -> state -> 'r) -> (error -> state -> 'r) -> 'r;
}

let ( let* ) p f =
  { run = (fun s ok err -> p.run s (fun x s' -> (f x).run s' ok err) err) }

let ( let+ ) p f =
  { run = (fun s ok err -> p.run s (fun x s' -> ok (f x) s') err) }

let ( <|> ) p1 p2 =
  { run = (fun s ok err -> p1.run s ok (fun e s' -> p2.run s ok err)) }

let return x = { run = (fun s ok err -> ok x s) }
let return_err e = { run = (fun s ok err -> err e { s with is_err = true }) }

let any_token =
  {
    run =
      (fun s ok err ->
        let token, lex' = Lexer.next_token s.lex in
        ok token { s with lex = lex' });
  }

let lookahead p = { run = (fun s ok err -> p.run s (fun x s' -> ok x s) err) }

let rec synchronize () =
  let* token = any_token in
  match token with
  | At (_, (Token.SemiColon | Token.Eof)) -> return ()
  | _ -> synchronize ()

let satisfy_map f =
  let* (At (loc, token)) = any_token in
  match f token with
  | Some x -> return (Located.At (loc, x))
  | None ->
      return_err
        (Located.At (loc, Errors.UnexpectedToken (Token.to_string token)))

let expect token = satisfy_map (fun x -> if x = token then Some () else None)

let save_loc p =
  {
    run =
      (fun s ok err ->
        let start_tok = fst (Lexer.next_token s.lex) in
        p.run s (fun x s' -> ok (Located.map (fun _ -> x) start_tok) s') err);
  }

let many p =
  {
    run =
      (fun s ok err ->
        let rec go acc s =
          let At (_, tok), _ = Lexer.next_token s.lex in
          if tok = Token.Eof then ok (List.rev acc) s
          else
            p.run s
              (fun x s' -> go (x :: acc) s')
              (fun _ s' -> ok (List.rev acc) s')
        in
        go [] s);
  }

let recover p con sync_lex =
  {
    run =
      (fun s ok _ ->
        let At (loc, _), _ = Lexer.next_token s.lex in
        p.run s
          (fun x s' -> ok x s')
          (fun _ s' ->
            ok
              (Located.At (loc, con (Located.At (loc, Errors.Stub))))
              { lex = (if sync_lex then s'.lex else s.lex); is_err = true }));
  }

let error_stub con =
  let* (At (loc, _)) = lookahead any_token in
  let* _ = synchronize () in
  return (Located.At (loc, con (Located.At (loc, Errors.Stub))))

let parse_ident = satisfy_map (function Token.Ident id -> Some id | _ -> None)
let parse_number = satisfy_map (function Token.Number n -> Some n | _ -> None)

let parse_binop () =
  satisfy_map (function
    | Plus -> Some Syntax.Add
    | Minus -> Some Syntax.Sub
    | Asterisk -> Some Syntax.Mul
    | Slash -> Some Syntax.Div
    | _ -> None)

let parse_ident_expr =
  let+ (Located.At (loc, _) as id) = parse_ident in
  Located.At (loc, Syntax.IdentExpr id)

let parse_intlit_expr =
  let+ (Located.At (loc, n)) = parse_number in
  let v = try Scanf.sscanf n "%Lu" Fun.id with _ -> 0L in
  Located.At (loc, Syntax.IntLitExpr (At (loc, v)))

let rec parse_primary_expr () =
  parse_ident_expr <|> parse_intlit_expr
  <|> (let* _ = expect Token.LParen in
       let* expr = parse_expr () in
       (let+ _ = expect Token.RParen in
        expr)
       <|> error_stub (fun x -> Syntax.ErrorExpr x))
  <|> error_stub (fun x -> Syntax.ErrorExpr x)

and parse_unary_expr () =
  (let* (Located.At (loc, _)) = expect Token.Minus in
   let* rhs = parse_unary_expr () in
   return (Located.At (loc, Syntax.UnaryOpExpr (At (loc, Syntax.Minus), rhs))))
  <|> parse_primary_expr ()

and parse_binop_expr prec =
  let* lhs = parse_unary_expr () in
  let rec loop lhs =
    (let* (Located.At (loc, binop)) = lookahead (parse_binop ()) in
     let next_prec = Syntax.binop_precedence binop in
     if next_prec > prec then
       let* _ = parse_binop () in
       let* rhs = parse_binop_expr next_prec in
       loop
         (Located.At (loc, Syntax.BinOpExpr (lhs, Located.At (loc, binop), rhs)))
     else return lhs)
    <|> return lhs
  in
  loop lhs

and parse_expr () =
  parse_binop_expr min_int <|> error_stub (fun x -> Syntax.ErrorExpr x)

let expect_semi = recover (expect Token.SemiColon) (fun _ -> ()) true

let parse_decl_with kw ctor =
  let* _ = expect kw in
  let* id = parse_ident in
  let* expr =
    recover
      (let* _ = expect Token.Assign in
       parse_expr ())
      (fun x -> Syntax.ErrorExpr x)
      false
  in
  return (ctor (id, expr))

let parse_var_decl =
  parse_decl_with Token.Var (fun (id, e) -> Syntax.VarDecl (id, e))

let parse_val_decl =
  parse_decl_with Token.Val (fun (id, e) -> Syntax.ValDecl (id, e))

let parse_decl =
  save_loc parse_var_decl <|> save_loc parse_val_decl
  <|> error_stub (fun x -> Syntax.ErrorDecl x)

let parse_return_stmt =
  save_loc
    (let* _ = expect Token.Return in
     let* e = parse_expr () in
     let* _ = expect_semi in
     return (Syntax.ReturnStmt e))

let parse_decl_stmt =
  save_loc
    (let* _ = lookahead (expect Token.Var <|> expect Token.Val) in
     let* d = parse_decl in
     let* _ = expect_semi in
     return (Syntax.DeclStmt d))

let parse_assign_stmt =
  let* (At (_, _) as id) = parse_ident in
  let* (At (loc, _)) = expect Token.Assign in
  let* e = parse_expr () in
  let* _ = expect_semi in
  return (Located.At (loc, Syntax.AssignStmt (id, e)))

let parse_expr_stmt =
  let* (At (loc, _) as e) = parse_expr () in
  let* _ = expect_semi in
  {
    run =
      (fun s ok _ ->
        ok (Located.At (loc, Syntax.ExprStmt e)) { s with is_err = true });
  }

let parse_stmt =
  recover
    (parse_return_stmt <|> parse_decl_stmt <|> parse_assign_stmt
   <|> parse_expr_stmt)
    (fun x -> Syntax.ErrorStmt x)
    true

let check_semantics (Located.At (_, stmts)) =
  let env, err = (Hashtbl.create 16, ref false) in
  let rec check_expr (Located.At (_, expr)) =
    match expr with
    | Syntax.IdentExpr (At (_, id)) ->
        if not (Hashtbl.mem env id) then err := true
    | Syntax.BinOpExpr (lhs, _, rhs) ->
        check_expr lhs;
        check_expr rhs
    | Syntax.UnaryOpExpr (_, e) -> check_expr e
    | _ -> ()
  in
  let chk_decl (Located.At (_, decl)) =
    match decl with
    | Syntax.ValDecl (At (_, id), expr) ->
        check_expr expr;
        if Hashtbl.mem env id then err := true else Hashtbl.add env id false
    | Syntax.VarDecl (At (_, id), expr) ->
        check_expr expr;
        if Hashtbl.mem env id then err := true else Hashtbl.add env id true
    | _ -> ()
  in
  List.iter
    (fun (Located.At (_, s)) ->
      match s with
      | Syntax.DeclStmt decl -> chk_decl decl
      | Syntax.AssignStmt (At (_, id), expr) ->
          check_expr expr;
          if Hashtbl.find_opt env id <> Some true then err := true
      | Syntax.ExprStmt expr | Syntax.ReturnStmt expr -> check_expr expr
      | _ -> ())
    stmts;
  !err

let parse lex : bool * string Syntax.t Located.t =
  let st, res =
    (save_loc (many parse_stmt)).run { lex; is_err = false }
      (fun tree s -> (s, tree))
      (fun _ s ->
        (s, Located.map (fun _ -> []) (fst @@ Lexer.next_token s.lex)))
  in
  (st.is_err || check_semantics res, res)
