module Lexer = struct
  type t = UnknownToken of char [@@deriving show]

  let to_string = function
    | UnknownToken s -> String.of_char s
end
