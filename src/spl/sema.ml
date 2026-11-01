module StringMap = Map.Make (String)

type t = {
  env : Syntax.mut StringMap.t;
  errors : Errors.t Located.t list;
  in_loop : bool;
}

let add_err st err = { st with errors = err :: st.errors }

let rec check_expr st (Located.At (loc, expr)) =
  match expr with
  | Syntax.IdentExpr id when not (StringMap.mem id st.env) ->
      add_err st (At (loc, UndeclaredIdentifier id))
  | Syntax.BinOpExpr (_, lhs, rhs) ->
      let st' = check_expr st lhs in
      check_expr st' rhs
  | Syntax.UnaryOpExpr (_, rhs) -> check_expr st rhs
  | _ -> st

let rec check_stmt st (Located.At (loc, stmt)) =
  match stmt with
  | Syntax.DeclStmt (mut, At (_, id), rhs) ->
      let st' =
        match StringMap.mem id st.env with
        | true -> add_err st (At (loc, Redeclaration id))
        | false -> st
      in
      let st'' = check_expr st' rhs in
      { st'' with env = StringMap.add id mut st''.env }
  | Syntax.AssignStmt (At (loc, id), rhs) ->
      let st' =
        match StringMap.find_opt id st.env with
        | Some Syntax.Val -> add_err st (At (loc, AssignToImmutable id))
        | Some Syntax.Var -> st
        | None -> add_err st (At (loc, UndeclaredIdentifier id))
      in
      check_expr st' rhs
  | Syntax.ExprStmt _ -> add_err st (At (loc, Errors.ExpressionResultUnused))
  | Syntax.ReturnStmt lexpr -> check_expr st lexpr
  | Syntax.IfStmt (cond, then_stmt, else_opt) -> (
      let st' = check_expr st cond in
      let st'' = check_stmt st' then_stmt in
      match else_opt with
      | Some else_stmt -> check_stmt st'' else_stmt
      | None -> st'')
  | Syntax.WhileStmt (cond, body) ->
      let in_loop = st.in_loop in
      let st' = check_expr st cond in
      let st'' = check_stmt { st' with in_loop = true } body in
      { st'' with in_loop }
  | Syntax.ContinueStmt ->
      if st.in_loop then st
      else add_err st (At (loc, Errors.ContinueOutsideLoop))
  | Syntax.BreakStmt ->
      if st.in_loop then st else add_err st (At (loc, Errors.BreakOutsideLoop))
  | _ -> st

let check_ast (Located.At (loc, tree)) =
  let st = { env = StringMap.empty; errors = []; in_loop = false } in
  let st' = List.fold_left (fun st stmt -> check_stmt st stmt) st tree in
  st'.errors
