module Lexer = struct
  type t = UnknownToken of string [@@deriving show]

  let to_string = function
    | UnknownToken s -> s
end
