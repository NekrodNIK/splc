open Cmdliner
open Cmdliner.Term.Syntax

let grammar_ver = 1

let rec splc src_path lr pr =
  let src = In_channel.with_open_text src_path In_channel.input_all in
  let lex = Spl.Lexer.from_string src in

  let lexing_error =
    match lr with
    | Some lr_path ->
        let report, error_flag = Spl.Report.report_lexer lex in
        let () = write_report report lr_path in
        error_flag
    | _ -> false
  in

  let parsing_error, syntax_tree = Spl.Parser.parse lex in
  let () =
    match pr with
    | Some pr_path ->
        let report = Spl.Report.report_ast syntax_tree in
        write_report report pr_path
    | _ -> ()
  in

  if lexing_error || parsing_error then Cmd.Exit.some_error else Cmd.Exit.ok

and write_report report path =
  (Fun.flip Yojson.Basic.pretty_to_channel) report
  |> Out_channel.with_open_text path

let cmd =
  Cmd.v (Cmd.info "splc")
  @@
  let+ src_path = Arg.(required & pos 0 (some file) None & info [] ~docv:"FILE")
  and+ lr = Arg.(value & opt (some path) None & info [ "t" ])
  and+ pr = Arg.(value & opt (some path) None & info [ "a" ])
  and+ _ =
    Arg.(
      value
      & opt (enum [ ([%string "%{grammar_ver#Int}"], grammar_ver) ]) grammar_ver
      & info [ "g" ])
  in
  splc src_path lr pr

let () = exit (Cmd.eval' cmd)
