open Result.Syntax

type t = string Located.t

let from_string src = Located.At (src, { offset = 0; line = 1; col = 1 })

type 'a res = ('a, Token.t Located.t) result

let peek st : char res =
  let (Located.At (src, loc)) = !st in
  if loc.offset < String.length src then Ok src.[loc.offset]
  else Error (Located.At(Token.Eof, loc))

let rec eat st : char res =
  let (Located.At (src, loc)) = !st in
  let+ ch = peek st in
  st :=
    Located.At
      ( src,
        {
          offset = loc.offset + 1;
          line = (loc.line + if ch == '\n' then 1 else 0);
          col = (1 + if ch == '\n' then 0 else loc.col);
        } );
  ch

let skip_whitespace st : bool res =
  let rec go flag =
    let* ch = peek st in
    match ch with
    | ' ' | '\t' | '\r' | '\n' ->
        let* _ = eat st in
        go true
    | _ -> Ok flag
  in
  go false

let rec skip_line st : unit res =
  let* ch = peek st in
  match ch with
  | '\n' ->
      let _ = eat st in
      Ok ()
  | _ -> skip_line st

let rec skip_multiline_comment st : unit res =
  let* str = Result.product (peek st) (peek st) in
  match str with
  | '*', '/' ->
      let* _ = Result.product (eat st) (eat st) in
      Ok ()
  | _ -> skip_multiline_comment st

let rec skip_comments st : bool res =
  let* str = Result.product (peek st) (peek st) in
  match str with
  | '/', '/' ->
      let* _ = skip_line st in
      Ok true
  | '/', '*' ->
      let* _ = skip_multiline_comment st in
      Ok true
  | _ -> Ok false

let rec skip_trivia st : unit res =
  let* found_ws = skip_whitespace st and* found_com = skip_comments st in
  if found_ws || found_com then skip_trivia st else Ok ()

let rec eat_while st pred : string res =
  let (Located.At (src, loc)) = !st in
  let start_offset = loc.offset in

  let rec calc_len x =
    let* ch = peek st in
    if pred ch then
      let* _ = eat st in
      calc_len (x + 1)
    else Ok x
  in
  let+ len = calc_len 0 in
  String.sub src start_offset len

let is_digit = Char.Ascii.is_digit
let is_alpha = Char.Ascii.is_letter
let is_alphanum = Char.Ascii.is_alphanum

let read_number st : Token.t res =
  let+ str = eat_while st is_digit in
  Token.Number (int_of_string str)

let read_ident st : Token.t res =
  let+ str = eat_while st is_alphanum in
  match str with
  | "val" -> Token.Val
  | "var" -> Token.Var
  | "return" -> Token.Return
  | id -> Token.Ident id

let read_token st : Token.t Located.t res =
  let (Located.At (_, loc)) = !st in
  let* ch = peek st in
  let token =
        match ch with
        | '(' -> let _ = eat st in Ok(Token.LParen)
        | ')' -> let _ = eat st in Ok(Token.RParen)
        | '+' -> let _ = eat st in Ok(Token.Plus)
        | '-' -> let _ = eat st in Ok(Token.Minus)
        | '/' -> let _ = eat st in Ok(Token.Slash)
        | '*' -> let _ = eat st in Ok(Token.Asterisk)
        | ';' -> let _ = eat st in Ok(Token.SemiColon)
        | '=' -> let _ = eat st in Ok(Token.Equal)
        | ch when is_digit ch -> read_number st
        | ch when is_alpha ch -> read_ident st
        | ch -> Error(Located.At(Token.Error(Errors.Lexer.UnknownToken(String.of_char ch)), loc))
  in
  Result.map (fun x -> Located.At(x, loc)) token

let next_token st =
  let st' = ref st in
  match skip_trivia st' with
  | Ok _ -> (
      match read_token st' with
      | Ok token -> (!st', token)
      | Error token -> (!st', token))
  | Error token -> (!st', token)
