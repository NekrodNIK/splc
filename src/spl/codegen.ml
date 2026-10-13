open Result.Syntax

type t = {
  context : Llvm.llcontext;
  builder : Llvm.llbuilder;
  cur_module : Llvm.llmodule;
  names : (string, Llvm.llvalue) Hashtbl.t;
}

type error = GetTargetError of string | WriteToFileError of string

let rec gen_expr st (Located.At (_, expr)) =
  match expr with
  | Syntax.IntLitExpr n -> Llvm.(const_of_int64 (i64_type st.context) n false)
  | Syntax.IdentExpr id ->
      let ptr = Hashtbl.find st.names id in
      Llvm.(build_load (i64_type st.context) ptr "" st.builder)
  | Syntax.UnaryOpExpr (_, expr) ->
      Llvm.build_neg (gen_expr st expr) "" st.builder
  | Syntax.BinOpExpr (binop, lhs, rhs) ->
      let build = function
        | Syntax.AddOp -> Llvm.build_add
        | Syntax.SubOp -> Llvm.build_sub
        | Syntax.MulOp -> Llvm.build_mul
        | Syntax.DivOp -> Llvm.build_sdiv
      in
      build binop (gen_expr st lhs) (gen_expr st rhs) "" st.builder
  | _ -> assert false

let gen_stmt st (Located.At (_, stmt)) =
  match stmt with
  | Syntax.ReturnStmt expr -> Llvm.build_ret (gen_expr st expr) st.builder
  | Syntax.DeclStmt (_, At (_, id), expr) ->
      let ptr = Llvm.(build_alloca (i64_type st.context) id st.builder) in
      let () = Hashtbl.add st.names id ptr in
      Llvm.build_store (gen_expr st expr) ptr st.builder
  | Syntax.AssignStmt (At (_, id), expr) ->
      let ptr = Hashtbl.find st.names id in
      Llvm.build_store (gen_expr st expr) ptr st.builder
  | _ -> assert false

let gen_func st =
  let func_type = Llvm.function_type (Llvm.i64_type st.context) [||] in
  let func = Llvm.define_function "main" func_type st.cur_module in
  let bb = Llvm.entry_block func in
  let () = Llvm.position_at_end bb st.builder in
  func

let gen_ast st (Located.At (_, ast)) =
  let _main = gen_func st in
  List.iter (Fun.compose ignore (gen_stmt st)) ast

let rec emit ~ast ~module_name ~output_path =
  let () = Llvm_all_backends.initialize () in
  let context = Llvm.create_context () in
  let cur_module = Llvm.create_module context module_name in
  let builder = Llvm.builder context in
  let names = Hashtbl.create 16 in
  let st = { context; cur_module; builder; names } in

  let* () = set_target st in
  let () = gen_ast st ast in

  try Ok (Llvm.print_module output_path st.cur_module)
  with Llvm.IoError s -> Error (WriteToFileError s)

and set_target st =
  let open Llvm_target in
  let triple = Target.default_triple () in
  let+ target =
    try Ok (Target.by_triple triple)
    with Llvm_target.Error s -> Error (GetTargetError s)
  in
  let tm = TargetMachine.create ~triple target in
  let data_layout = TargetMachine.data_layout tm |> DataLayout.as_string in
  Llvm.set_target_triple triple st.cur_module;
  Llvm.set_data_layout data_layout st.cur_module
