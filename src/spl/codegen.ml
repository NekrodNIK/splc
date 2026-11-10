open Result.Syntax

type t = {
  context : Llvm.llcontext;
  builder : Llvm.llbuilder;
  cur_module : Llvm.llmodule;
  mutable cur_func : Llvm.llvalue;
  mutable loop_cond_bb : Llvm.llbasicblock;
  mutable loop_end_bb : Llvm.llbasicblock;
  names : (string, Llvm.llvalue) Hashtbl.t;
}

type error = GetTargetError of string | WriteToFileError of string

let const_i64 st x = Llvm.(const_of_int64 (i64_type st.context) x false)

let const_i1 st x =
  Llvm.(const_of_int64 (i1_type st.context) (if x then 1L else 0L) false)

let gen_to_int64 st value =
  Llvm.build_zext value (Llvm.i64_type st.context) "" st.builder

let gen_to_bool st value =
  Llvm.(build_icmp Icmp.Ne value (const_i64 st 0L) "" st.builder)

let gen_unop st op rhs =
  match op with
  | Syntax.NegOp -> Llvm.build_neg rhs "" st.builder
  | Syntax.NotOp ->
      Llvm.build_not (gen_to_bool st rhs) "" st.builder |> gen_to_int64 st

let rec gen_expr st (Located.At (_, expr)) =
  match expr with
  | Syntax.IntLitExpr n -> const_i64 st n
  | Syntax.BoolLitExpr value -> const_i64 st (if value then 1L else 0L)
  | Syntax.IdentExpr id ->
      let ptr = Hashtbl.find st.names id in
      Llvm.build_load (Llvm.i64_type st.context) ptr "" st.builder
  | Syntax.BinOpExpr (binop, lhs, rhs) -> gen_binop st binop lhs rhs
  | Syntax.UnaryOpExpr (unop, rhs) -> gen_unop st unop (gen_expr st rhs)
  | _ -> assert false

and gen_binop st op lhs_expr rhs_expr =
  let icmp c x y name b =
    Llvm.build_icmp c
      (x |> gen_expr st)
      (y |> gen_expr st)
      name st.builder
    |> gen_to_int64 st
  in
  let eager c x y name b = c (gen_expr st x) (gen_expr st y) name b in
  let short_circuit c x y name b =
    let lhs = gen_to_bool st (gen_expr st x) in
    let append_block () = Llvm.append_block st.context "" st.cur_func in
    let then_bb = append_block () in
    let else_bb = append_block () in
    let cont_bb = append_block () in

    let rhs =
      match op with
      | Syntax.AndOp ->
          let _ = Llvm.build_cond_br lhs then_bb else_bb b in
          Llvm.position_at_end then_bb st.builder;
          let rhs1 = gen_to_bool st (gen_expr st y) in
          ignore (Llvm.build_br cont_bb b);
          Llvm.position_at_end else_bb st.builder;
          ignore (Llvm.build_br cont_bb b);
          [ (rhs1, then_bb); (const_i1 st false, else_bb) ]
      | Syntax.OrOp ->
          let _ =
            Llvm.build_cond_br (Llvm.build_not lhs "" b) then_bb else_bb b
          in
          Llvm.position_at_end then_bb st.builder;
          let rhs1 = gen_to_bool st (gen_expr st y) in
          ignore (Llvm.build_br cont_bb b);
          Llvm.position_at_end else_bb st.builder;
          ignore (Llvm.build_br cont_bb b);
          [ (rhs1, then_bb); (const_i1 st true, else_bb) ]
      | _ -> assert false
    in
    Llvm.position_at_end cont_bb st.builder;
    Llvm.build_phi rhs name b |> gen_to_int64 st
  in

  let build =
    match op with
    | Syntax.AddOp -> eager Llvm.build_add
    | Syntax.SubOp -> eager Llvm.build_sub
    | Syntax.MulOp -> eager Llvm.build_mul
    | Syntax.DivOp -> eager Llvm.build_sdiv
    | Syntax.AndOp -> short_circuit Llvm.build_add
    | Syntax.OrOp -> short_circuit Llvm.build_or
    | Syntax.LtOp -> icmp Llvm.Icmp.Slt
    | Syntax.LeOp -> icmp Llvm.Icmp.Sle
    | Syntax.GtOp -> icmp Llvm.Icmp.Sgt
    | Syntax.GeOp -> icmp Llvm.Icmp.Sge
    | Syntax.EqOp -> icmp Llvm.Icmp.Eq
    | Syntax.NeOp -> icmp Llvm.Icmp.Ne
  in
  build lhs_expr rhs_expr "" st.builder

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
    | Syntax.ContinueStmt -> ignore @@ Llvm.build_br st.loop_cond_bb st.builder
    | Syntax.BreakStmt -> ignore @@ Llvm.build_br st.loop_end_bb st.builder
    | Syntax.IfStmt (cond, then_stmt, else_opt) ->
        let append_block name = Llvm.append_block st.context name st.cur_func in

        let then_bb = append_block "if.then" in
        let else_bb, ifcont_bb =
          match else_opt with
          | Some _ -> (append_block "if.else", append_block "if.cont")
          | None -> (fun x -> (x, x)) (append_block "if.cont")
        in

        let cond_val = gen_to_bool st (gen_expr st cond) in
        let _ = Llvm.build_cond_br cond_val then_bb else_bb st.builder in

        let _ = gen_branch st then_bb ifcont_bb then_stmt in
        let _ = Option.iter (gen_branch st else_bb ifcont_bb) else_opt in

        Llvm.position_at_end ifcont_bb st.builder
    | Syntax.WhileStmt (cond, body_stmt) ->
        let prev_cond_bb = st.loop_cond_bb in
        let prev_end_bb = st.loop_end_bb in

        let cond_bb = Llvm.append_block st.context "while.cond" st.cur_func in
        let body_bb = Llvm.append_block st.context "while.body" st.cur_func in
        let end_bb = Llvm.append_block st.context "while.end" st.cur_func in

        st.loop_cond_bb <- cond_bb;
        st.loop_end_bb <- end_bb;
        let _ = Llvm.build_br cond_bb st.builder in

        Llvm.position_at_end cond_bb st.builder;
        let cond_val = gen_to_bool st (gen_expr st cond) in
        let _ = Llvm.build_cond_br cond_val body_bb end_bb st.builder in

        gen_branch st body_bb cond_bb body_stmt;

        st.loop_cond_bb <- prev_cond_bb;
        st.loop_end_bb <- prev_end_bb;
        Llvm.position_at_end end_bb st.builder
    | _ -> assert false

and gen_branch st bb cont_bb stmt =
  Llvm.position_at_end bb st.builder;
  gen_stmt st stmt;
  if block_is_open st then ignore @@ Llvm.build_br cont_bb st.builder

let gen_ast st (Located.At (_, ast)) =
  let () = List.iter (Fun.compose ignore (gen_stmt st)) ast in
  if block_is_open st then ignore @@ Llvm.build_ret (const_i64 st 0L) st.builder

let rec emit ~ast ~module_name ~output_path =
  let () = Llvm_all_backends.initialize () in
  let context = Llvm.create_context () in
  let cur_module = Llvm.create_module context module_name in
  let builder = Llvm.builder context in
  let names = Hashtbl.create 16 in

  let func_type = Llvm.function_type (Llvm.i64_type context) [||] in
  let func = Llvm.define_function "main" func_type cur_module in
  let bb = Llvm.entry_block func in
  let () = Llvm.position_at_end bb builder in

  let st =
    {
      context;
      cur_module;
      cur_func = func;
      builder;
      names;
      loop_cond_bb = bb;
      loop_end_bb = bb;
    }
  in

  let* () = set_target st in
  let () = gen_ast st ast in

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
