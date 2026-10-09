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
  | Ident x | Number x -> x
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

let length token =
  match token with
  | Ident x | Number x -> String.length x
  | Val | Var -> 3
  | Return -> 6
  | Assign | Plus | Minus | Slash | Asterisk | SemiColon | LParen | RParen -> 1
  | _ -> 0
