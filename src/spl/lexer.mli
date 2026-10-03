type t  
val from_string : string -> t
val next_token : t -> Token.t Located.t * t
val to_list : t -> Token.t Located.t list
