open Cmdliner
open Cmdliner.Term.Syntax

let grammar_ver = 1

let splc src_path lr pr =
  let src = In_channel.with_open_text src_path In_channel.input_all in
  let lex = Spl.Lexer.from_string src in
  let ast, parser_errors = Spl.Parser.parse lex in

  if Option.is_some lr || Option.is_some pr then
    let lexer_flag =
      match lr with
      | Some lr_path ->
          let report, error_flag = Spl.Report.report_lexer lex in
          let () =
            Out_channel.with_open_text lr_path
            @@ (Fun.flip Yojson.Basic.pretty_to_channel) report
          in
          error_flag
      | _ -> false
    in

    let parser_flag =
      match pr with
      | Some pr_path ->
          let report = Spl.Report.report_ast Fun.id ast in
          let () =
            Out_channel.with_open_text pr_path
            @@ (Fun.flip Yojson.Basic.pretty_to_channel) report
          in
          List.is_empty parser_errors
      | _ -> false
    in
    if lexer_flag || parser_flag then Cmd.Exit.some_error else Cmd.Exit.ok
  else if List.is_empty parser_errors then
    Cmd.Exit.ok
  else
    let () = List.iter (Spl.Errors.print_error src_path src) parser_errors in
    Cmd.Exit.some_error

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
