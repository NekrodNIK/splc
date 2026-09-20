open Cmdliner
open Cmdliner.Term.Syntax

let grammar_ver = 1

let splc src_path lr =
  let lex =
    Spl.Lexer.from_string
    @@ In_channel.with_open_text src_path In_channel.input_all
  in

  match lr with
  | Some lr_path ->
      Out_channel.with_open_text lr_path
      @@ (Fun.flip Yojson.Basic.pretty_to_channel) (Spl.Report.report_lexer lex)
  | _ -> ()

let cmd =
  Cmd.v (Cmd.info "splc")
  @@
  let+ src_path = Arg.(required & pos 0 (some file) None & info [] ~docv:"FILE")
  and+ lr = Arg.(value & opt (some path) None & info [ "t" ])
  and+ _ =
    Arg.(
      value
      & opt (enum [ ([%string "%{grammar_ver#Int}"], grammar_ver) ]) grammar_ver
      & info [ "g" ])
  in
  splc src_path lr

let () = exit (Cmd.eval cmd)
