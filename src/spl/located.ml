type location = { offset : int; line : int; col : int } [@@deriving show]
type 'a t = At of location * 'a [@@deriving show]

let zero_location = {offset=0; line=1; col=1}

let map (f : 'a -> 'b) (At (loc, x) : 'a t) = At (loc, f x)
let get (At (_, x) : 'a t) = x
let get_loc (At (loc, _) : 'a t) = loc
