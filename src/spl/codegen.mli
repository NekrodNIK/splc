type t
val run : string Syntax.t Located.t -> string -> t
val emit : t -> string -> unit 
