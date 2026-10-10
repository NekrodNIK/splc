type binop = AddOp | SubOp | MulOp | DivOp
type unop = NegOp
type mut = Val | Var

type 'id expr =
  | BinOpExpr of binop * 'id lexpr * 'id lexpr
  | UnaryOpExpr of unop * 'id lexpr
  | IdentExpr of 'id
  | IntLitExpr of int64
  | ErrorExpr of lerror

and 'id stmt =
  | ExprStmt of 'id lexpr
  | ReturnStmt of 'id lexpr
  | DeclStmt of mut * 'id lid * 'id lexpr
  | AssignStmt of 'id lid * 'id lexpr
  | ErrorStmt of lerror

and 'id lexpr = 'id expr Located.t
and 'id lstmt = 'id stmt Located.t
and lerror = Errors.t Located.t
and 'id lid = 'id Located.t

type 'id t = 'id lstmt list

let binop_precedence = function AddOp | SubOp -> 1 | MulOp | DivOp -> 2

let binop_to_string = function
  | AddOp -> "+"
  | SubOp -> "-"
  | MulOp -> "*"
  | DivOp -> "/"

let unop_to_string = function NegOp -> "-"

let mut_to_string = function Val -> "Val" | Var -> "Var"
