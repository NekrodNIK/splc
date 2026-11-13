(* FIXME: refactor *)
module StringMap = Map.Make (String)

type t = { env : Syntax.mut StringMap.t; errors : Errors.t Located.t list }

let empty = { env = StringMap.empty; errors = [] }
let add_error loc err st = { st with errors = At (loc, err) :: st.errors }
let bind_id id mut st = { st with env = StringMap.add id mut st.env }

let check_declarable id loc st =
  if StringMap.mem id st.env then add_error loc (Redeclaration id) st else st

let check_assignable id loc st =
  match StringMap.find_opt id st.env with
  | None -> add_error loc (UndeclaredIdentifier id) st
  | Some Syntax.Val -> add_error loc (AssignToImmutable id) st
  | Some _ -> st

let check_bounded id loc st =
  match StringMap.find_opt id st.env with
  | Some _ -> st
  | None -> add_error loc (UndeclaredIdentifier id) st

let rec check_expr (Located.At (loc, expr)) st =
  match expr with
  | Syntax.IdentExpr id when not (StringMap.mem id st.env) ->
      add_error loc (UndeclaredIdentifier id) st
  | BinOpExpr (_, lhs, rhs) -> check_expr lhs st |> check_expr rhs
  | UnaryOpExpr (_, rhs) -> check_expr rhs st
  | _ -> st

let rec check_stmt ?(in_loop = false) (Located.At (loc, stmt)) st =
  match stmt with
  | Syntax.DeclStmt (mut, At (_, id), rhs) ->
      check_declarable id loc st |> check_expr rhs |> bind_id id mut
  | Syntax.AssignStmt (At (loc, id), rhs) ->
      check_assignable id loc st |> check_expr rhs
  (* | Syntax.ExprStmt _ -> add_error loc ExpressionResultUnused st *)
  | Syntax.ReturnStmt expr -> check_expr expr st
  | Syntax.IfStmt (cond, then_stmt, Some else_stmt) ->
      st
      |> check_expr cond
      |> check_stmt ~in_loop then_stmt
      |> check_stmt ~in_loop else_stmt
  | Syntax.IfStmt (cond, then_stmt, None) ->
      check_expr cond st |> check_stmt ~in_loop then_stmt
  | Syntax.WhileStmt (cond, body_stmt) ->
      check_expr cond st |> check_stmt ~in_loop:true body_stmt
  | Syntax.ContinueStmt ->
      if not in_loop then add_error loc ContinueOutsideLoop st else st
  | Syntax.BreakStmt ->
      if not in_loop then add_error loc BreakOutsideLoop st else st
  | Syntax.BlockStmt stmts ->
      let st' = List.fold_left (Fun.flip (check_stmt ~in_loop)) st stmts in
      { st with errors = st'.errors }
  | _ -> st

let rec always_returns (Located.At (loc, stmt)) =
  match stmt with
  | Syntax.ReturnStmt _ -> true
  | Syntax.IfStmt (cond, then_stmt, Some else_stmt) ->
      always_returns then_stmt && always_returns else_stmt
  | Syntax.IfStmt (cond, then_stmt, None) -> false
  | Syntax.BlockStmt stmts -> List.exists always_returns stmts
  | _ -> false

let check_always_returns stmt st =
  if always_returns stmt then st
  else add_error (Located.get_loc stmt) Errors.MissingReturn st

let check_top_decl (Located.At (loc, top_decl)) st =
  match top_decl with
  | Syntax.FuncTopDecl (At (loc, id), _, _)
  | Syntax.ExternTopDecl (At (loc, id), _) ->
      check_declarable id loc st |> bind_id id Val

let check_func_body id params body st =
  List.fold_left
    (fun st (Located.At (loc, param)) ->
      check_declarable param loc st |> bind_id param Var)
    st params
  |> check_stmt body
  |> check_always_returns body

let check_main_declared st = check_bounded "main" Located.zero_location st

let check_ast (Located.At (loc, tree)) =
  let st =
    List.fold_left (Fun.flip check_top_decl) empty tree
    |> check_main_declared
    |> Fun.flip
         (List.fold_left (fun st -> function
           | Located.At (_, Syntax.FuncTopDecl (At (_, id), params, body)) ->
               let st' = check_func_body id params body st in
               { st with errors = st'.errors }
           | _ -> st))
         tree
  in
  st.errors
