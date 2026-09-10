type t = { offset : int; line : int; col : int } [@@deriving show]
type 'a located = Located of 'a * t [@@deriving show]

let located_to_json (l: 'a located) (inner_to_json : 'a -> Yojson.Basic.t) =
  let Located (inner, pos) = l in
  Yojson.Basic.Util.combine (inner_to_json inner) @@ `Assoc [
    ("line", `Int pos.line);
    ("column", `Int pos.col);
  ]
