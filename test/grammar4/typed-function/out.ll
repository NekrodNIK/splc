; ModuleID = 'spl'
source_filename = "spl"

define i64 @add(i64 %0, i64 %1) {
entry:
  %a = alloca i64, align 8
  store i64 %0, ptr %a, align 4
  %b = alloca i64, align 8
  store i64 %1, ptr %b, align 4
  %a1 = load i64, ptr %a, align 4
  %b2 = load i64, ptr %b, align 4
  %addtmp = add i64 %a1, %b2
  ret i64 %addtmp
}

define i64 @main() {
entry:
  %result = alloca i64, align 8
  %calltmp = call i64 @add(i64 3, i64 4)
  store i64 %calltmp, ptr %result, align 4
  %result1 = load i64, ptr %result, align 4
  ret i64 %result1
}
