type t = UnterminatedMultilineComment | UnknownToken of char | UnexpectedToken of string | UnclosedParen
[@@deriving show]

let to_string = function
  | UnterminatedMultilineComment -> "Unterminated multi-line comment"
  | UnknownToken ch -> [%string "Unknown token '%{String.of_char ch}'"]
  | UnexpectedToken token -> [%string "Unexpected token token"]
  | UnclosedParen -> "Unclosed parenthesis"
