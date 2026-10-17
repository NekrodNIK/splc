type t  
val from_string : string -> t
val next_token : t -> Token.t Located.t * t
