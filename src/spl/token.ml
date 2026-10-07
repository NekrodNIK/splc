type t =
  | Ident of string
  | Number of string
  | Val
  | Var
  | Assign
  | Return
  | Plus
  | Minus
  | Slash
  | Asterisk
  | SemiColon
  | LParen
  | RParen
  | Error of Errors.t
  | Eof
[@@deriving show]

let to_string token : string =
  match token with
  | Ident x -> x
  | Number x -> x
  | Val -> "val"
  | Var -> "var"
  | Assign -> "="
  | Return -> "return"
  | Plus -> "+"
  | Minus -> "-"
  | Slash -> "/"
  | Asterisk -> "*"
  | SemiColon -> ";"
  | LParen -> "("
  | RParen -> ")"
  | Error err -> Errors.to_string err
  | Eof -> ""
