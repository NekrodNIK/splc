type error = Token.lexer_error

type t = {
  src : string;
  mutable pos : Position.t;
  mutable errors : error Position.located list;
}

let from_string src =
  { src; pos = { offset = 0; line = 1; col = 1 }; errors = [] }

let peek buf : char =
  if buf.pos.offset >= String.length buf.src then raise_notrace End_of_file;
  buf.src.[buf.pos.offset]

let rec eat buf : char =
  let ch = peek buf in
  buf.pos <-
    {
      offset = buf.pos.offset + 1;
      line = (buf.pos.line + if ch == '\n' then 1 else 0);
      col = 1 + (if ch == '\n' then 0 else buf.pos.col);
    };
  ch

let skip buf = ignore @@ eat buf

let skip_whitespace buf : bool =
  let rec go state =
    let ch = peek buf in
    match ch with
    | ' ' | '\t' | '\r' | '\n' ->
        skip buf;
        go true
    | _ -> state
  in
  go false

let rec skip_line buf : unit =
  match eat buf with '\n' -> () | _ -> skip_line buf

let rec skip_multiline_comment buf : unit =
  match eat buf with
  | '*' -> (
      match eat buf with
      | '/' -> ()
      | _ ->
          let error = Position.Located (Token.UnclosedMultilineComment, buf.pos) in
          buf.errors <- List.cons error buf.errors)
  | _ -> skip_multiline_comment buf

let rec skip_comments buf : bool =
  match peek buf with
  | '/' -> (
      skip buf;
      match eat buf with
      | '/' ->
          skip_line buf;
          true
      | '*' ->
          skip_multiline_comment buf;
          true
      | _ -> false)
  | _ -> false

let rec skip_trivia buf : unit =
  let found_ws = skip_whitespace buf in
  let found_com = skip_comments buf in
  if found_ws || found_com then skip_trivia buf

let rec eat_while buf (pred : char -> bool) : string =
  let start = buf.pos.offset in
  let rec calc_len x =
    if pred (peek buf) then (
      skip buf;
      calc_len (x + 1))
    else x
  in
  String.sub buf.src start (calc_len 0)

let is_digit = Char.Ascii.is_digit
let is_alpha = Char.Ascii.is_letter
let is_alphanum = Char.Ascii.is_alphanum

let read_number buf : Token.t =
  Token.Number (int_of_string @@ eat_while buf is_digit)

let read_ident buf : Token.t =
  match eat_while buf is_alphanum with
  | "val" -> Token.Val
  | "var" -> Token.Var
  | "return" -> Token.Return
  | id -> Token.Ident id

let read_token buf : Token.t Position.located =
  skip_trivia buf;
  let pos = buf.pos in

  let ch = peek buf in
  (match String.contains "()+-/*;=" ch with
  | true ->
      let _ = skip buf in
      ()
  | false -> ());

  let token =
    match ch with
    | '(' -> Token.LParen
    | ')' -> Token.RParen
    | '+' -> Token.Plus
    | '-' -> Token.Minus
    | '/' -> Token.Slash
    | '*' -> Token.Asterisk
    | ';' -> Token.SemiColon
    | '=' -> Token.Equal
    | ch when is_digit ch -> read_number buf
    | ch when is_alpha ch -> read_ident buf
    | ch -> skip buf; Token.Asterisk
  in
  Position.Located (token, pos)

let next_token buf =
  try read_token buf with End_of_file -> Position.Located (Token.Eof, buf.pos)

let errors buf = buf.errors
