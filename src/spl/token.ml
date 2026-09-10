type lexer_error = UnclosedMultilineComment | UnknownToken of string
[@@deriving show]

let lexer_error_to_string = function
  | UnclosedMultilineComment -> "Unclosed multiline comment"
  | UnknownToken s -> s

type t =
  | Ident of string
  | Number of int
  | Val
  | Var
  | Equal
  | Return
  | Plus
  | Minus
  | Slash
  | Asterisk
  | SemiColon
  | LParen
  | RParen
  | Error of lexer_error
  | Eof
[@@deriving show]

let to_string token : string =
  match token with
  | Ident x -> x
  | Number x -> Int.to_string x
  | Val -> "val"
  | Var -> "var"
  | Equal -> "="
  | Return -> "return"
  | Plus -> "+"
  | Minus -> "-"
  | Slash -> "/"
  | Asterisk -> "*"
  | SemiColon -> ";"
  | LParen -> "("
  | RParen -> ")"
  | Error err -> lexer_error_to_string err
  | Eof -> ""

let to_json token : Yojson.Basic.t =
  let kind =
    match token with
    | Ident _ -> "IDENT"
    | Number _ -> "NUM"
    | Val -> "VAL"
    | Var -> "VAR"
    | Equal -> "EQUAL"
    | Return -> "RETURN"
    | Plus -> "PLUS"
    | Minus -> "MINUS"
    | Slash -> "SLASH"
    | Asterisk -> "ASTERISK"
    | SemiColon -> "SEMICOLON"
    | LParen -> "LPAREN"
    | RParen -> "RPAREN"
    | Error err -> "ERROR"
    | Eof -> "EOF"
  in
  `Assoc [ ("kind", `String kind); ("value", `String (to_string token)) ]
