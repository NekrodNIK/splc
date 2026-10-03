type location = { offset : int; line : int; col : int } [@@deriving show]
type 'a t = At of location * 'a [@@deriving show]

let get (At (_, x) : 'a t) = x

let to_json (inner_to_json : 'a -> Yojson.Basic.t) (l : 'a t) =
  let (At (loc, inner)) = l in
  Yojson.Basic.Util.combine (inner_to_json inner)
  @@ `Assoc [ ("line", `Int loc.line); ("column", `Int loc.col) ]
