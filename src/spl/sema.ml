let rec check_lexpr env lexpr : bool =
  match Located.get lexpr with
  | Syntax.IdentExpr id when not (Hashtbl.mem env id) -> true
  | Syntax.BinOpExpr (_, lhs, rhs) -> check_lexpr env lhs || check_lexpr env rhs
  | Syntax.UnaryOpExpr (_, rhs) -> check_lexpr env rhs
  | _ -> false

let rec check_stmt env ldecl : bool =
  match Located.get ldecl with
  | Syntax.DeclStmt (mut, At (_, id), rhs) ->
      let res = Hashtbl.mem env id || check_lexpr env rhs in
      let () = Hashtbl.add env id (mut = Syntax.Val) in
      res
  | Syntax.AssignStmt (At (_, id), rhs) ->
      check_lexpr env rhs
      || Option.value (Hashtbl.find_opt env id) ~default:false
  | Syntax.ExprStmt lexpr | Syntax.ReturnStmt lexpr -> check_lexpr env lexpr
  | _ -> false

let check_ast (tree : 'id Syntax.t) : bool =
  let env = Hashtbl.create 16 in
  List.fold_left (fun acc stmt -> acc || check_stmt env stmt) false tree
