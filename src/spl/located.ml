type location = { offset : int; line : int; col : int } [@@deriving show]
type 'a t = At of 'a * location [@@deriving show]

let map (f: 'a -> 'b) (At(inner, loc) : 'a t) : 'b t =
  At(f inner, loc)

let to_json (l : 'a t) (inner_to_json : 'a -> Yojson.Basic.t) =
  let At (inner, loc) = l in
  Yojson.Basic.Util.combine (inner_to_json inner)
  @@ `Assoc [ ("line", `Int loc.line); ("column", `Int loc.col) ]
