(* TODO: refactor it *)

type 'a loc = 'a Located.t
type binop = Add | Sub | Mul | Div
type unop = Minus

type 'id expr =
  | BinOpExpr of 'id expr loc * binop loc * 'id expr loc
  | UnaryOpExpr of unop loc * 'id expr loc
  | IdentExpr of 'id loc
  | IntLitExpr of int64 loc
  | ErrorExpr of Errors.t loc

type 'id decl =
  | ValDecl of 'id loc * 'id expr loc
  | VarDecl of 'id loc * 'id expr loc
  | ErrorDecl of Errors.t loc

type 'id stmt =
  | ExprStmt of 'id expr loc
  | ReturnStmt of 'id expr loc
  | DeclStmt of 'id decl loc
  | AssignStmt of 'id loc * 'id expr loc
  | ErrorStmt of Errors.t loc

type 'id t = 'id stmt loc list

let binop_precedence = function Add | Sub -> 1 | Mul | Div -> 2

let binop_to_string op =
  match op with Add -> "+" | Sub -> "-" | Mul -> "*" | Div -> "/"

let unop_to_string op = match op with Minus -> "-"

let pack_node kind elems comment =
  let node = [ ("kind", `String kind); ("elems", `List elems) ] in
  `Assoc
    (match comment with
    | "" -> node
    | _ -> ("comment", `String comment) :: node)

let rec expr_to_json (id_to_string : 'id -> string) (ex : 'id expr) =
  let nested = Located.to_json (expr_to_json id_to_string) in
  match ex with
  | BinOpExpr (lhs, At (_, op), rhs) ->
      pack_node "BinOp" [ nested lhs; nested rhs ] (binop_to_string op)
  | UnaryOpExpr (At (_, op), ex') ->
      pack_node "Unary" [ nested ex' ] (unop_to_string op)
  | IdentExpr (At (_, id)) -> pack_node "Ident" [] (id_to_string id)
  | IntLitExpr (At (_, n)) -> pack_node "IntLiteral" [] (Int64.to_string n)
  | ErrorExpr err ->
      Located.to_json (fun x -> pack_node "Error" [] (Errors.to_string x)) err

let decl_to_json (id_to_string : 'id -> string) (de : 'id decl) =
  let nested_expr = Located.to_json (expr_to_json id_to_string) in
  let nested_ident = Located.to_json (fun _ -> pack_node "Ident" [] "") in
  match de with
  | ValDecl (id, ex) ->
      pack_node "Declare" [ nested_ident id; nested_expr ex ] "Val"
  | VarDecl (id, ex) ->
      pack_node "Declare" [ nested_ident id; nested_expr ex ] "Var"
  | ErrorDecl err ->
      Located.to_json (fun x -> pack_node "Error" [] (Errors.to_string x)) err

let stmt_to_json (id_to_string : 'id -> string) (st : 'id stmt) =
  let nested_expr = Located.to_json (expr_to_json id_to_string)
  and nested_decl = Located.to_json (decl_to_json id_to_string) in
  let nested_ident = Located.to_json (fun _ -> pack_node "Ident" [] "") in
  match st with
  | ExprStmt ex -> nested_expr ex
  | ReturnStmt ex -> pack_node "Return" [ nested_expr ex ] ""
  | DeclStmt de -> nested_decl de
  | AssignStmt (id, ex) ->
      pack_node "Assign" [ nested_ident id; nested_expr ex ] ""
  | ErrorStmt err ->
      Located.to_json (fun x -> pack_node "Error" [] (Errors.to_string x)) err

let to_json (id_to_string : 'id -> string) (ast : 'id t) =
  pack_node "Program"
    (List.map (Located.to_json (stmt_to_json id_to_string)) ast)
    ""
