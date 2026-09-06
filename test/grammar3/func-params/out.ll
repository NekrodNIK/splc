; ModuleID = 'spl'
source_filename = "spl"

define i64 @add(i64 %0, i64 %1) {
entry:
  %a = alloca i64, align 8
  store i64 %0, ptr %a, align 8
  %b = alloca i64, align 8
  store i64 %1, ptr %b, align 8
  %result = alloca i64, align 8
  %a1 = load i64, ptr %a, align 8
  %b2 = load i64, ptr %b, align 8
  %addtmp = add i64 %a1, %b2
  store i64 %addtmp, ptr %result, align 8
  %result3 = load i64, ptr %result, align 8
  ret i64 %result3
}
