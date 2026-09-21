module Lexer = struct
  type t = UnterminatedMultilineComment | UnknownToken of char
  [@@deriving show]

  let to_string = function
    | UnterminatedMultilineComment -> "Unterminated multi-line comment"
    | UnknownToken s -> String.of_char s
end
