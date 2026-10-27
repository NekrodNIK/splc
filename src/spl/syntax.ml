type binop =
  | AddOp
  | SubOp
  | MulOp
  | DivOp
  | AndOp
  | OrOp
  | LtOp
  | LeOp
  | GtOp
  | GeOp
  | EqOp
  | NeOp
[@@deriving show]

type unop = NegOp | NotOp [@@deriving show]
type mut = Val | Var [@@deriving show]

type 'id expr =
  | BinOpExpr of binop * 'id lexpr * 'id lexpr
  | UnaryOpExpr of unop * 'id lexpr
  | IdentExpr of 'id
  | IntLitExpr of int64
  | BoolLitExpr of bool
  | ErrorExpr of lerror
[@@deriving show]

and 'id stmt =
  | ExprStmt of 'id lexpr
  | ReturnStmt of 'id lexpr
  | DeclStmt of mut * 'id lid * 'id lexpr
  | AssignStmt of 'id lid * 'id lexpr
  | IfStmt of 'id lexpr * 'id lstmt * 'id lstmt option
  | WhileStmt of 'id lexpr * 'id lstmt
  | BreakStmt
  | ContinueStmt
  | BlockStmt of 'id lstmt list
  | ErrorStmt of lerror
[@@deriving show]

and 'id lexpr = 'id expr Located.t [@@deriving show]
and 'id lstmt = 'id stmt Located.t [@@deriving show]
and lerror = Errors.t Located.t [@@deriving show]
and 'id lid = 'id Located.t [@@deriving show]

type 'id t = 'id lstmt list [@@deriving show]

let binop_precedence = function
  | AndOp | OrOp -> 1
  | EqOp | NeOp -> 2
  | LtOp | LeOp | GtOp | GeOp -> 3
  | AddOp | SubOp -> 4
  | MulOp | DivOp -> 5

let binop_min_precedence = 1

let binop_to_string = function
  | AndOp -> "&&"
  | OrOp -> "||"
  | EqOp -> "=="
  | NeOp -> "!="
  | LtOp -> "<"
  | LeOp -> "<="
  | GtOp -> ">"
  | GeOp -> ">="
  | AddOp -> "+"
  | SubOp -> "-"
  | MulOp -> "*"
  | DivOp -> "/"

let unop_to_string = function NegOp -> "-" | NotOp -> "!"
let mut_to_string = function Val -> "Val" | Var -> "Var"
