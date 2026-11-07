type ('a, 'r) parser =
  state -> ('a -> state -> 'r) -> (error -> state -> 'r) -> 'r

and state = {
  lex : Lexer.t;
  last_token : Token.t Located.t;
  error_list : error list;
}

and error = Errors.t Located.t

let ( let* ) par f = fun st ok err -> par st (fun x st' -> (f x) st' ok err) err
let ( let+ ) par f = fun st ok err -> par st (fun x st' -> ok (f x) st') err
let return x = fun st ok _ -> ok x st
let return_err e = fun st _ err -> err e st

let register_err e par =
 fun st -> par { st with error_list = e :: st.error_list }

let lookahead par = fun st ok err -> par st (fun x _ -> ok x st) err

let ( <|> ) par1 par2 =
 fun st ok err ->
  par1 st ok @@ fun e st' ->
  if st'.lex = st.lex then par2 st' ok err else err e st'

let empty =
 fun st _ err ->
  err
    (let loc = Located.get_loc st.last_token in
     Located.At (loc, Errors.Expected { expected = "empty"; actual = "bebebe" }))
    st

let not_followed_by par =
 fun st ok err -> par st (fun _ _ -> empty st ok err) (fun _ _ -> ok () st)

let try_ par = fun st ok err -> par st ok (fun e _ -> err e st)

let with_recovery recovery par =
 fun st ok err -> par st ok (fun e st' -> recovery e st' ok err)

let many par =
 fun st ok err ->
  let rec go acc st =
    let At (_, token), _ = Lexer.next_token st.lex in
    if token = Token.Eof then ok (List.rev acc) st
    else
      par st
        (fun x st' -> go (x :: acc) st')
        (fun _ st' -> ok (List.rev acc) st')
  in
  go [] st

let get_last_token = fun st ok err -> ok st.last_token st

let any_token =
 fun st ->
  let At (loc, token), lex' = Lexer.next_token st.lex in
  let st' = { st with lex = lex'; last_token = At (loc, token) } in
  match token with
  | Token.Error e -> return_err (Located.At (loc, e)) st'
  | _ -> return (Located.At (loc, token)) st'

let satisfy_map name f =
  let* (At (loc, token)) = lookahead any_token in
  match f token with
  | Some x ->
      let+ _ = any_token in
      Located.At (loc, x)
  | None ->
      let error =
        Errors.Expected { expected = name; actual = Token.to_string token }
      in
      return_err @@ Located.At (loc, error)

let expect token =
  satisfy_map (Token.to_string token) @@ function
  | x when x = token -> Some x
  | _ -> None

let synchronize tokens =
  let rec go () =
    let* (At (_, token)) = lookahead any_token in
    match token with
    | tk when List.mem tk tokens -> return ()
    | Token.Eof -> return ()
    | _ ->
        let* _ = any_token in
        go ()
  in
  go ()

let save_loc par =
  let* (At (loc, _)) = lookahead any_token in
  let+ x = par in
  Located.At (loc, x)

let make_initial_state lex =
  let loc = Located.zero_location in
  { lex; last_token = At (loc, Token.Eof); error_list = [] }

let get_state = fun st ok _ -> ok st st
let get_errors st = st.error_list

let has_errors par =
  let* head = ( let+ ) get_state get_errors in
  let* x = par in
  let+ head' = ( let+ ) get_state get_errors in
  (x, head != head')

let run_parser par st =
  let x, error_list =
    save_loc par st
      (fun x st' -> (x, st'.error_list))
      (fun _ st' -> (Located.At (Located.zero_location, []), st'.error_list))
  in
  (x, List.rev error_list)
