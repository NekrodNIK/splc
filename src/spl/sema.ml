let rec check_expr env (Located.At (loc, expr)) =
  match expr with
  | Syntax.IdentExpr id when not (Hashtbl.mem env id) ->
      [ Located.At (loc, Errors.UndeclaredIdentifier id) ]
  | Syntax.BinOpExpr (_, lhs, rhs) -> check_expr env lhs @ check_expr env rhs
  | Syntax.UnaryOpExpr (_, rhs) -> check_expr env rhs
  | _ -> []

let rec check_stmt env (Located.At (loc, stmt)) =
  match stmt with
  | Syntax.DeclStmt (mut, At (_, id), rhs) ->
      let res =
        (if Hashtbl.mem env id then
           [ Located.At (loc, Errors.Redeclaration id) ]
         else [])
        @ check_expr env rhs
      in
      let () = Hashtbl.add env id mut in
      res
  | Syntax.AssignStmt (At (loc, id), rhs) ->
      (match Hashtbl.find_opt env id with
        | Some Syntax.Val -> [ Located.At (loc, Errors.AssignToImmutable id) ]
        | Some Syntax.Var -> []
        | None -> [ Located.At (loc, Errors.UndeclaredIdentifier id) ])
      @ check_expr env rhs
  | Syntax.ExprStmt _ -> [ At (loc, Errors.ExpressionResultUnused) ]
  | Syntax.ReturnStmt lexpr -> check_expr env lexpr
  | _ -> []

let check_ast (Located.At (_, tree)) =
  let env = Hashtbl.create 16 in
  List.fold_left (fun acc stmt -> acc @ check_stmt env stmt) [] tree
