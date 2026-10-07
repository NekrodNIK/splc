type location = { offset : int; line : int; col : int } [@@deriving show]
type 'a t = At of location * 'a [@@deriving show]

let map (f : 'a -> 'b) (At(loc, x) : 'a t) = At(loc, f x)
let get (At (_, x) : 'a t) = x
