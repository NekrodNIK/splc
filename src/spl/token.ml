type t =
  | Ident of string
  | Number of string
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
  | Error of Errors.t
  | Eof
[@@deriving show]

let to_string token : string =
  match token with
  | Ident x | Number x -> x
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
  | Error err -> Errors.to_string err
  | Eof -> ""

let length token =
  match token with
  | Ident x | Number x -> String.length x
  | True -> 4
  | False -> 5
  | Val | Var -> 3
  | Return -> 6
  | If -> 2
  | Else -> 4
  | While | Break -> 5
  | Continue -> 8
  | LParen | RParen | LBrace | RBrace | Semi -> 1
  | Assign | Plus | Minus | Star | Slash | Lt | Gt | Not -> 1
  | And | Or | Eq | Ne | Le | Ge -> 2
  | Error _ | Eof -> 0
