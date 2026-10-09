type t =
  | UnterminatedMultilineComment
  | UnknownToken of char
  | MissingSemiColon
  | Expected of { expected: string; actual: string }
[@@deriving show]

let to_string = function
  | UnterminatedMultilineComment -> "unterminated multi-line comment"
  | UnknownToken ch -> [%string "unknown token '%{String.of_char ch}'"]
  | MissingSemiColon -> "missing semicolon"
  | Expected { expected; actual } -> [%string "expected \"%{expected}\", actual: \"%{actual}\""]

let red s = [%string "\x1b[31m%{s}\x1b[0m"]
let bold s = [%string "\x1b[1m%{s}\x1b[0m"]

let print_error filepath src (At (loc, err) : t Located.t) =
  let lines = String.split_on_char '\n' src in
  let line = List.nth lines (loc.line - 1) in
  let idnum = Int.to_string loc.line in
  let ident = String.make (String.length idnum) ' ' in
  {%string|
%{red @@ bold "error"}: %{to_string err}
%{ident} -> %{filepath}:%{loc.line#Int}:%{loc.col#Int}
%{ident} |
%{idnum} | %{line}
%{ident} | %{String.make (loc.col-1) ' '}%{red @@ bold "^"}
|}
  |> String.trim |> print_string |> print_newline
