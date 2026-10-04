open Cmdliner
open Cmdliner.Term.Syntax

let grammar_ver = 1

let splc src_path lr pr =
  let lex =
    Spl.Lexer.from_string
    @@ In_channel.with_open_text src_path In_channel.input_all
  in

  let result =
    match lr with
    | Some lr_path ->
        let report, error_flag = Spl.Report.report_lexer lex in
        let () =
          Out_channel.with_open_text lr_path
          @@ (Fun.flip Yojson.Basic.pretty_to_channel) report
        in
        if error_flag then Cmd.Exit.some_error else Cmd.Exit.ok
    | _ -> Cmd.Exit.ok
  in

  let () =
    match pr with
    | Some pr_path ->
        let report = Spl.Report.report_parser lex in
        Out_channel.with_open_text pr_path
        @@ (Fun.flip Yojson.Basic.pretty_to_channel) report
    | _ -> ()
  in

  result

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
