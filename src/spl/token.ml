type t =
  | Ident of string
  | NumberLiteral of string
  | StringLiteral of string
  | True
  | False
  | Val
  | Var
  | Return
  | If
  | Else
  | While
  | Break
  | Continue
  | LParen
  | RParen
  | LBrace
  | RBrace
  | Semi
  | Colon
  | Comma
  | Assign
  | Plus
  | Minus
  | Star
  | Slash
  | And
  | Or
  | Not
  | Eq
  | Ne
  | Lt
  | Le
  | Gt
  | Ge
  | Extern
  | Def
  | Cast
  (* *)
  | Int8
  | Int16
  | Int32
  | Int64
  | Bool
  | Void
  | String
  (* *)
  | Error of Errors.t
  | Eof
[@@deriving show]

let to_string token : string =
  match token with
  | Ident x | NumberLiteral x | StringLiteral x -> x
  | True -> "true"
  | False -> "false"
  | Val -> "val"
  | Var -> "var"
  | Return -> "return"
  | If -> "if"
  | Else -> "else"
  | While -> "while"
  | Break -> "break"
  | Continue -> "continue"
  | LParen -> "("
  | RParen -> ")"
  | LBrace -> "{"
  | RBrace -> "}"
  | Semi -> ";"
  | Colon -> ":"
  | Comma -> ","
  | Assign -> "="
  | Plus -> "+"
  | Minus -> "-"
  | Star -> "*"
  | Slash -> "/"
  | And -> "&&"
  | Or -> "||"
  | Not -> "!"
  | Eq -> "=="
  | Ne -> "!="
  | Lt -> "<"
  | Le -> "<="
  | Gt -> ">"
  | Ge -> ">="
  | Extern -> "extern"
  | Def -> "def"
  | Cast -> "cast"
  (* *)
  | Int8 -> "Int8"
  | Int16 -> "Int16"
  | Int32 -> "Int32"
  | Int64 -> "Int64"
  | Bool-> "Bool"
  | Void -> "Void"
  | String -> "String"
  (* *)
  | Error err -> Errors.to_string err
  | Eof -> ""

let length token =
  match token with
  | Ident x | NumberLiteral x | StringLiteral x -> String.length x
  | True -> 4
  | False -> 5
  | Val | Var -> 3
  | Return -> 6
  | If -> 2
  | Else -> 4
  | While | Break -> 5
  | Continue -> 8
  | LParen | RParen | LBrace | RBrace | Semi | Colon | Comma -> 1
  | Assign | Plus | Minus | Star | Slash | Lt | Gt | Not -> 1
  | And | Or | Eq | Ne | Le | Ge -> 2
  | Extern -> 6
  | Def -> 3
  | Cast -> 4
  (* *)
  | Int8
  | Bool 
  | Void -> 4
  | Int16 
  | Int32
  | Int64 -> 5
  | String -> 6
  (* *)
  | Error _ | Eof -> 0
