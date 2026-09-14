module Lexer = struct
  type t = UnclosedMultilineComment | UnknownToken of string [@@deriving show]

  let to_string = function
    | UnclosedMultilineComment -> "Unclosed multiline comment"
    | UnknownToken s -> s
end
