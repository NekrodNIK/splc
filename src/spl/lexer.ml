open Result.Syntax

type t = { src : string; loc : Located.location }

let from_string src = { src; loc = { offset = 0; line = 1; col = 1 } }

type 'a res = ('a, Token.t Located.t) result

let peek st : char res =
  let { src; loc } = !st in
  if loc.offset < String.length src then Ok src.[loc.offset]
  else Error (At (Eof, loc))

let peek_string st upper : string =
  let { src; loc } = !st in
  String.sub src loc.offset (min upper (String.length src - loc.offset))

let eat st : char res =
  let { src; loc } = !st in
  let+ ch = peek st in
  st :=
    {
      src;
      loc =
        {
          offset = loc.offset + 1;
          line = (loc.line + if ch = '\n' then 1 else 0);
          col = (1 + if ch = '\n' then 0 else loc.col);
        };
    };
  ch

let rec eat_n st n : unit res =
  if n = 0 then Ok ()
  else
    let* _ = eat st in
    eat_n st (n - 1)

let eat_while st pred : string res =
  let start_offset = !st.loc.offset in
  let rec go x =
    match peek st with
    | Ok ch when pred ch ->
        let* _ = eat st in
        go (x + 1)
    | _ -> Ok x
  in

  let+ len = go 0 in
  String.sub !st.src start_offset len

let is_digit = Char.Ascii.is_digit
let is_non_digit ch = Char.Ascii.is_letter ch || ch = '_'
let is_whitespace = function ' ' | '\t' | '\r' | '\n' -> true | _ -> false

let rec skip_multiline_comment st start_loc : unit res =
  match peek_string st 2 with
  | "*/" -> eat_n st 2
  | "" -> Error (At (Token.Error UnterminatedMultilineComment, start_loc))
  | _ ->
      let* _ = eat st in
      skip_multiline_comment st start_loc

let rec skip_trivia st : unit res =
  let* _ = eat_while st is_whitespace in
  match peek_string st 2 with
  | "//" ->
      let* _ = eat_while st (( <> ) '\n') in
      skip_trivia st
  | "/*" ->
      let start_loc = !st.loc in
      let* _ = eat_n st 2 in
      let* _ = skip_multiline_comment st start_loc in
      skip_trivia st
  | _ -> Ok ()

let read_number st : Token.t res =
  let+ str = eat_while st is_digit in
  Token.Number (int_of_string str)

let read_ident st : Token.t res =
  let+ str = eat_while st (fun ch -> is_digit ch || is_non_digit ch) in
  match str with
  | "val" -> Token.Val
  | "var" -> Token.Var
  | "return" -> Token.Return
  | id -> Token.Ident id

let read_token st : Token.t Located.t res =
  let loc = !st.loc in
  let* ch = peek st in

  let single tok = Result.map (fun _ -> tok) (eat st)
  and single_err tok = Result.bind (eat st) (fun _ -> Error (At (tok, loc))) in

  let token =
    match ch with
    | '(' -> single Token.LParen
    | ')' -> single Token.RParen
    | '+' -> single Token.Plus
    | '-' -> single Token.Minus
    | '/' -> single Token.Slash
    | '*' -> single Token.Asterisk
    | ';' -> single Token.SemiColon
    | '=' -> single Token.Assign
    | '0' -> single (Token.Number 0)
    | ch when is_digit ch -> read_number st
    | ch when is_non_digit ch -> read_ident st
    | ch -> single_err (Token.Error (UnknownToken ch))
  in
  Result.map (fun x -> Located.At (x, loc)) token

let next_token st =
  let st' = ref st in
  let result =
    let* _ = skip_trivia st' in
    read_token st'
  in
  match result with Ok token | Error token -> (!st', token)
