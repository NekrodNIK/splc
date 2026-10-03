type t = UnterminatedMultilineComment | UnknownToken of char
[@@deriving show]

let to_string = function
  | UnterminatedMultilineComment -> "Unterminated multi-line comment"
  | UnknownToken ch -> [%string "Unknown token '%{String.of_char ch}'"]
