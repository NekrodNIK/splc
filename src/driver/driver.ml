let usage_msg = "Usage: splc [options] [file].."

module CmdArgs = struct
  let grammar_ver = 1
  let srcs = ref []
  let report_lexer = ref None
end

let exitf =
  Printf.ksprintf (fun s ->
      prerr_string s;
      exit 1)

let grammar_check x =
  if x != CmdArgs.grammar_ver then exitf "unsupported grammar version"

let speclist =
  [
    ("-g", Arg.Int grammar_check, "grammar version");
    ( "-t",
      Arg.String (fun s -> CmdArgs.report_lexer := Some s),
      "enable lexer report to file" );
  ]

let add_src path =
  let text = In_channel.with_open_text path In_channel.input_all in
  CmdArgs.srcs := text :: !CmdArgs.srcs

let report_lexer token_gens path =
  let rec unfold_until_eof f =
    match f () with
    | Spl.Position.Located (Spl.Token.Eof, _) -> []
    | x -> x :: unfold_until_eof f
  in

  Out_channel.with_open_bin path (fun oc ->
      List.iter
        (fun gen ->
          let jsons = `List(
            List.map
              (fun p -> Spl.Position.located_to_json p Spl.Token.to_json)
              (unfold_until_eof gen))
          in
            Out_channel.output_string oc (Yojson.Basic.pretty_to_string jsons);
            Out_channel.output_char oc '\n')
        token_gens)

let () =
  Arg.parse speclist add_src usage_msg;
  if !CmdArgs.srcs == [] then exitf "no input files";

  let token_gens =
    List.map
      (fun s ->
        let lexbuf = Spl.Lexer.from_string s in
        fun () -> Spl.Lexer.next_token lexbuf)
      !CmdArgs.srcs
  in

  match !CmdArgs.report_lexer with
  | Some path -> report_lexer token_gens path
  | None -> ()
