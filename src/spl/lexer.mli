type error = Token.lexer_error
type t  
val from_string : string -> t
val next_token : t -> Token.t Position.located
