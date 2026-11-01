(* FIXME *)
open Result.Syntax

type t = {
  context : Llvm.llcontext;
  builder : Llvm.llbuilder;
  cur_module : Llvm.llmodule;
  mutable cur_func : Llvm.llvalue;
  mutable cond_bb : Llvm.llbasicblock;
  mutable end_bb : Llvm.llbasicblock;
  names : (string, Llvm.llvalue) Hashtbl.t;
}

type error = GetTargetError of string | WriteToFileError of string

let rec gen_expr st (Located.At (_, expr)) =
  match expr with
  | Syntax.IntLitExpr n -> Llvm.(const_of_int64 (i64_type st.context) n false)
  | Syntax.IdentExpr id ->
      let ptr = Hashtbl.find st.names id in
      Llvm.(build_load (i64_type st.context) ptr "" st.builder)
  | Syntax.BoolLitExpr value ->
      Llvm.(
        const_of_int64 (i64_type st.context)
          (Int64.of_int (Bool.to_int value))
          false)
  | Syntax.UnaryOpExpr (unop, expr) ->
      let build = function
        | Syntax.NegOp -> Llvm.build_neg
        | Syntax.NotOp ->
            fun expr _ builder ->
              let res =
                (Fun.compose Llvm.build_not (gen_cast_to_bool st))
                  expr "" builder
              in
              Llvm.build_zext res (Llvm.i64_type st.context) "" builder
      in
      build unop (gen_expr st expr) "" st.builder
  | Syntax.BinOpExpr (binop, lhs, rhs) -> (
      let build lhs_val rhs_val =
        let lhs_val', rhs_val' =
          match binop with
          | AndOp | OrOp ->
              (gen_cast_to_bool st lhs_val, gen_cast_to_bool st rhs_val)
          | _ -> (lhs_val, rhs_val)
        in
        (match binop with
        | Syntax.AddOp -> Llvm.build_add
        | Syntax.SubOp -> Llvm.build_sub
        | Syntax.MulOp -> Llvm.build_mul
        | Syntax.DivOp -> Llvm.build_sdiv
        | Syntax.AndOp -> Llvm.build_and
        | Syntax.OrOp -> Llvm.build_or
        | Syntax.LtOp -> Llvm.(build_icmp Icmp.Slt)
        | Syntax.LeOp -> Llvm.(build_icmp Icmp.Sle)
        | Syntax.GtOp -> Llvm.(build_icmp Icmp.Sgt)
        | Syntax.GeOp -> Llvm.(build_icmp Icmp.Sge)
        | Syntax.EqOp -> Llvm.(build_icmp Icmp.Eq)
        | Syntax.NeOp -> Llvm.(build_icmp Icmp.Ne))
          lhs_val' rhs_val'
      in
      let res = build (gen_expr st lhs) (gen_expr st rhs) "" st.builder in
      match binop with
      | AndOp | OrOp | LtOp | LeOp | GtOp | GeOp | EqOp | NeOp ->
          Llvm.build_zext res (Llvm.i64_type st.context) "" st.builder
      | _ -> res)
  | _ -> assert false

and gen_cast_to_bool st value =
  Llvm.(build_icmp Icmp.Ne value (const_zero st) "" st.builder)

and const_zero st = Llvm.(const_of_int64 (i64_type st.context) 0L false)

let is_terminated b =
  Option.is_some (Llvm.block_terminator (Llvm.insertion_block b))

let rec gen_stmt st (Located.At (_, stmt)) =
  match stmt with
  | Syntax.BlockStmt stmts -> List.iter (fun stmt -> gen_stmt st stmt) stmts
  | Syntax.IfStmt (cond, then_stmt, else_opt) ->
      let append_block name = Llvm.append_block st.context name st.cur_func in

      let cond_instr = gen_cast_to_bool st (gen_expr st cond) in
      let then_bb = append_block "then" in
      let else_bb =
        append_block (if Option.is_some else_opt then "else" else "ifcont")
      in
      let ifcont_bb =
        match else_opt with Some _ -> append_block "ifcont" | _ -> else_bb
      in

      let _ = Llvm.build_cond_br cond_instr then_bb else_bb st.builder in

      let build_branch bb stmt =
        Llvm.position_at_end bb st.builder;
        gen_stmt st stmt;
        if not (is_terminated st.builder) then
          ignore @@ Llvm.build_br ifcont_bb st.builder
      in

      let _ = build_branch then_bb then_stmt in
      let _ = Option.map (fun stmt -> build_branch else_bb stmt) else_opt in

      Llvm.position_at_end ifcont_bb st.builder
  | Syntax.WhileStmt (cond, body_stmt) ->
      let cond_bb = Llvm.append_block st.context "" st.cur_func in
      let body_bb = Llvm.append_block st.context "" st.cur_func in
      let end_bb = Llvm.append_block st.context "" st.cur_func in
      st.cond_bb <- cond_bb;
      st.end_bb <- end_bb;

      let _ = Llvm.build_br cond_bb st.builder in
      let () = Llvm.position_at_end cond_bb st.builder in
      let cond_instr = gen_cast_to_bool st (gen_expr st cond) in
      let _ = Llvm.build_cond_br cond_instr body_bb end_bb st.builder in

      let () = Llvm.position_at_end body_bb st.builder in
      let _ = gen_stmt st body_stmt in
      if not (is_terminated st.builder) then
        ignore @@ Llvm.build_br cond_bb st.builder;

      Llvm.position_at_end end_bb st.builder
  | Syntax.ContinueStmt -> ignore @@ Llvm.build_br st.cond_bb st.builder
  | Syntax.BreakStmt -> ignore @@ Llvm.build_br st.end_bb st.builder
  | Syntax.ReturnStmt expr ->
      ignore @@ Llvm.build_ret (gen_expr st expr) st.builder
  | Syntax.DeclStmt (_, At (_, id), expr) ->
      let ptr = Llvm.(build_alloca (i64_type st.context) id st.builder) in
      let () = Hashtbl.add st.names id ptr in
      ignore @@ Llvm.build_store (gen_expr st expr) ptr st.builder
  | Syntax.AssignStmt (At (_, id), expr) ->
      let ptr = Hashtbl.find st.names id in
      ignore @@ Llvm.build_store (gen_expr st expr) ptr st.builder
  | _ -> assert false

let gen_ast st (Located.At (_, ast)) =
  let () = List.iter (Fun.compose ignore (gen_stmt st)) ast in
  if not (is_terminated st.builder) then
    ignore @@ Llvm.build_ret (const_zero st) st.builder

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
      cond_bb = bb;
      end_bb = bb;
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
