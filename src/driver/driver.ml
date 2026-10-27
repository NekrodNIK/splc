open Cmdliner
open Cmdliner.Term.Syntax

let rec splc src_path out_path lr pr emit_llvm =
  let src = In_channel.with_open_text src_path In_channel.input_all in
  let lex = Spl.Lexer.from_string src in

  let has_error =
    if Option.is_none lr && Option.is_none pr then
      run src lex src_path out_path emit_llvm
    else
      let lexer_error =
        match lr with Some lr_path -> lexer_report lex lr_path | None -> false
      and parser_error =
        match pr with
        | Some pr_path -> parser_report lex pr_path
        | None -> false
      in
      lexer_error || parser_error
  in
  if has_error then Cmd.Exit.some_error else Cmd.Exit.ok

and run src lex src_path out_path emit_llvm =
  let ast, errors = Spl.Parser.parse lex in
  match errors with
  | [] -> run_codegen ast src_path out_path emit_llvm
  | errors ->
      let print_error error =
        let () = prerr_string (Spl.Errors.error_message src_path src error) in
        prerr_newline ()
      in
      let () = List.iter print_error errors in
      true

and run_codegen ast src_path out_path emit_llvm =
  let src_name = Filename.basename src_path in
  let llvm_out =
    if emit_llvm then out_path else Filename.temp_file "spl." ".ll"
  in
  match Spl.Codegen.emit ~ast ~module_name:src_name ~output_path:llvm_out with
  | Ok () when emit_llvm -> false
  | Ok () -> (
      let exit_code =
        Sys.command
        @@ Filename.quote_command "clang" [ llvm_out; "-o"; out_path ]
      in
      match exit_code with
      | 0 -> false
      | n ->
          prerr_string [%string "clang failed with exit code: %{n#Int}"];
          true)
  | Error Spl.Codegen.(GetTargetError s | WriteToFileError s) ->
      prerr_string s;
      true

and lexer_report lex lr_path =
  let report, error_flag = Spl.Report.report_lexer lex in
  let () =
    Out_channel.with_open_text lr_path
      ((Fun.flip Yojson.Basic.pretty_to_channel) report)
  in
  error_flag

and parser_report lex pr_path =
  let ast, parser_errors = Spl.Parser.parse lex in
  let report = Spl.Report.report_ast Fun.id ast in
  let () =
    Out_channel.with_open_text pr_path
      ((Fun.flip Yojson.Basic.pretty_to_channel) report)
  in
  not (List.is_empty parser_errors)

let cmd =
  Cmd.v (Cmd.info "splc")
  @@
  let+ src_path = Arg.(required & pos 0 (some file) None & info [] ~docv:"FILE")
  and+ out_path = Arg.(value & opt (some path) (Some "a.out") & info [ "o" ])
  and+ lr = Arg.(value & opt (some path) None & info [ "t" ])
  and+ pr = Arg.(value & opt (some path) None & info [ "a" ])
  and+ emit_llvm = Arg.(value & flag & info [ "emit-llvm" ])
  and+ _ =
    Arg.(
      value
      & opt (enum [ ("1", 1); ("2", 2) ]) 2
      & info [ "g" ])
  in
  splc src_path (Option.get out_path) lr pr emit_llvm

let () = exit (Cmd.eval' cmd)
