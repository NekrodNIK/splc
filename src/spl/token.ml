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

let to_json token : Yojson.Basic.t =
  let kind =
    match token with
    | Ident _ -> "IDENT"
    | Number _ -> "INT"
    | Val -> "VAL"
    | Var -> "VAR"
    | Assign -> "ASSIGN"
    | Return -> "RETURN"
    | Plus -> "PLUS"
    | Minus -> "MINUS"
    | Slash -> "DIV"
    | Asterisk -> "MULT"
    | SemiColon -> "SEMI"
    | LParen -> "LPAREN"
    | RParen -> "RPAREN"
    | Error err -> "ERROR"
    | Eof -> "EOF"
  in
  `Assoc [ ("kind", `String kind); ("value", `String (to_string token)) ]
