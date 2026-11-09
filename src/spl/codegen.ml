open Result.Syntax

type loop_context = { cond_bb : Llvm.llbasicblock; end_bb : Llvm.llbasicblock }

type t = {
  context : Llvm.llcontext;
  builder : Llvm.llbuilder;
  cur_module : Llvm.llmodule;
  mutable cur_func : Llvm.llvalue;
  mutable loop_context : loop_context;
  names : (string, Llvm.llvalue) Hashtbl.t;
}

type error = GetTargetError of string | WriteToFileError of string

let const_i64 st x = Llvm.(const_of_int64 (i64_type st.context) x false)

let const_i1 st x =
  Llvm.(const_of_int64 (i1_type st.context) (if x then 1L else 0L) false)

let to_i64 st v = Llvm.(build_zext v (i64_type st.context) "" st.builder)
let to_i1 st v = Llvm.(build_icmp Icmp.Ne v (const_i64 st 0L) "" st.builder)
let cur_block st = Llvm.insertion_block st.builder
let append_block st name = Llvm.append_block st.context name st.cur_func

let gen_unop st op rhs =
  match op with
  | Syntax.NegOp -> Llvm.build_neg rhs "" st.builder
  | Syntax.NotOp -> Llvm.build_not (to_i1 st rhs) "" st.builder |> to_i64 st

let rec gen_expr st (Located.At (_, expr)) =
  match expr with
  | Syntax.IntLitExpr n -> const_i64 st n
  | Syntax.BoolLitExpr value -> const_i64 st (if value then 1L else 0L)
  | Syntax.IdentExpr id ->
      let ptr = Hashtbl.find st.names id in
      Llvm.build_load (Llvm.i64_type st.context) ptr "" st.builder
  | Syntax.BinOpExpr (binop, lhs, rhs) -> gen_binop st binop lhs rhs
  | Syntax.UnaryOpExpr (unop, rhs) -> gen_unop st unop (gen_expr st rhs)
  | _ -> failwith "unsupported expr"

and gen_binop st op lhs_expr rhs_expr =
  let icmp c =
    Llvm.build_icmp c (gen_expr st lhs_expr) (gen_expr st rhs_expr) ""
      st.builder
    |> to_i64 st
  in
  let eager build =
    build (gen_expr st lhs_expr) (gen_expr st rhs_expr) "" st.builder
  in
  let short_circuit ~is_and =
    let lhs = to_i1 st (gen_expr st lhs_expr) in
    let lhs_bb = cur_block st in

    let rhs_bb = append_block st "logic.rhs" in
    let end_bb = append_block st "logic.end" in

    let _ =
      if is_and then Llvm.build_cond_br lhs rhs_bb end_bb st.builder
      else Llvm.build_cond_br lhs end_bb rhs_bb st.builder
    in
    let short_value = const_i1 st (not is_and) in

    Llvm.position_at_end rhs_bb st.builder;
    let rhs = to_i1 st (gen_expr st rhs_expr) in
    let rhs_bb = cur_block st in
    let _ = Llvm.build_br end_bb st.builder in

    Llvm.position_at_end end_bb st.builder;
    Llvm.build_phi [ (short_value, lhs_bb); (rhs, rhs_bb) ] "" st.builder
    |> to_i64 st
  in

  match op with
  | Syntax.AddOp -> eager Llvm.build_add
  | Syntax.SubOp -> eager Llvm.build_sub
  | Syntax.MulOp -> eager Llvm.build_mul
  | Syntax.DivOp -> eager Llvm.build_sdiv
  | Syntax.AndOp -> short_circuit ~is_and:true
  | Syntax.OrOp -> short_circuit ~is_and:false
  | Syntax.LtOp -> icmp Llvm.Icmp.Slt
  | Syntax.LeOp -> icmp Llvm.Icmp.Sle
  | Syntax.GtOp -> icmp Llvm.Icmp.Sgt
  | Syntax.GeOp -> icmp Llvm.Icmp.Sge
  | Syntax.EqOp -> icmp Llvm.Icmp.Eq
  | Syntax.NeOp -> icmp Llvm.Icmp.Ne

let block_is_open st =
  st.builder |> Llvm.insertion_block |> Llvm.block_terminator |> Option.is_none

let rec gen_stmt st (Located.At (_, stmt)) =
  if block_is_open st then
    match stmt with
    | Syntax.BlockStmt stmts -> List.iter (gen_stmt st) stmts
    | Syntax.DeclStmt (_, At (_, id), expr) ->
        let ptr = Llvm.(build_alloca (i64_type st.context) id st.builder) in
        let () = Hashtbl.add st.names id ptr in
        ignore @@ Llvm.build_store (gen_expr st expr) ptr st.builder
    | Syntax.AssignStmt (At (_, id), expr) ->
        let ptr = Hashtbl.find st.names id in
        ignore @@ Llvm.build_store (gen_expr st expr) ptr st.builder
    | Syntax.ReturnStmt expr ->
        ignore @@ Llvm.build_ret (gen_expr st expr) st.builder
    | Syntax.ContinueStmt ->
        ignore @@ Llvm.build_br st.loop_context.cond_bb st.builder
    | Syntax.BreakStmt ->
        ignore @@ Llvm.build_br st.loop_context.end_bb st.builder
    | Syntax.IfStmt (cond_expr, then_stmt, else_opt) ->
        let then_bb = append_block st "if.then" in
        let else_bb, ifcont_bb =
          match else_opt with
          | Some _ -> (append_block st "if.else", append_block st "if.cont")
          | None -> (fun x -> (x, x)) (append_block st "if.cont")
        in

        let cond = to_i1 st (gen_expr st cond_expr) in
        let _ = Llvm.build_cond_br cond then_bb else_bb st.builder in

        let _ = gen_branch st then_bb ifcont_bb then_stmt in
        let _ = Option.iter (gen_branch st else_bb ifcont_bb) else_opt in

        Llvm.position_at_end ifcont_bb st.builder
    | Syntax.WhileStmt (cond_expr, body_stmt) ->
        let prev_cond_bb = st.loop_context.cond_bb in
        let prev_end_bb = st.loop_context.end_bb in

        let cond_bb = append_block st "while.cond" in
        let body_bb = append_block st "while.body" in
        let end_bb = append_block st "while.end" in

        st.loop_context <- { cond_bb; end_bb };
        let _ = Llvm.build_br cond_bb st.builder in

        Llvm.position_at_end cond_bb st.builder;
        let cond = to_i1 st (gen_expr st cond_expr) in
        let _ = Llvm.build_cond_br cond body_bb end_bb st.builder in

        gen_branch st body_bb cond_bb body_stmt;

        st.loop_context <- { cond_bb = prev_cond_bb; end_bb = prev_end_bb };
        Llvm.position_at_end end_bb st.builder
    | _ -> assert false

and gen_branch st bb cont_bb stmt =
  Llvm.position_at_end bb st.builder;
  gen_stmt st stmt;
  if block_is_open st then ignore @@ Llvm.build_br cont_bb st.builder

let gen_ast st (Located.At (_, ast)) =
  List.iter (Fun.compose ignore (gen_stmt st)) ast;
  if block_is_open st then ignore @@ Llvm.build_ret (const_i64 st 0L) st.builder

let rec emit ~ast ~module_name ~output_path =
  Llvm_all_backends.initialize ();
  let context = Llvm.create_context () in
  let cur_module = Llvm.create_module context module_name in
  let builder = Llvm.builder context in
  let names = Hashtbl.create 16 in

  let func_type = Llvm.function_type (Llvm.i64_type context) [||] in
  let func = Llvm.define_function "main" func_type cur_module in
  let bb = Llvm.entry_block func in
  Llvm.position_at_end bb builder;

  let st =
    {
      context;
      cur_module;
      cur_func = func;
      builder;
      names;
      loop_context = { cond_bb = bb; end_bb = bb };
    }
  in

  let* () = set_target st in
  (* let () = gen_ast st ast in *)

  try Ok (Llvm.print_module output_path st.cur_module)
  with Llvm.IoError s -> Error (WriteToFileError s)

and set_target st =
  let open Llvm_target in
  let triple = "x86_64-unknown-linux-gnu" in
  let+ target =
    try Ok (Target.by_triple triple)
    with Llvm_target.Error s -> Error (GetTargetError s)
  in
  let tm = TargetMachine.create ~triple target in
  let data_layout = TargetMachine.data_layout tm |> DataLayout.as_string in
  Llvm.set_target_triple triple st.cur_module;
  Llvm.set_data_layout data_layout st.cur_module
