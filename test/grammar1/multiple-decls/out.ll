; ModuleID = 'spl'
source_filename = "spl"

define i64 @main() {
entry:
  %a = alloca i64, align 8
  store i64 1, ptr %a, align 8
  %b = alloca i64, align 8
  store i64 2, ptr %b, align 8
  %c = alloca i64, align 8
  store i64 3, ptr %c, align 8
  %a1 = load i64, ptr %a, align 8
  %b2 = load i64, ptr %b, align 8
  %addtmp = add i64 %a1, %b2
  %c3 = load i64, ptr %c, align 8
  %addtmp4 = add i64 %addtmp, %c3
  ret i64 %addtmp4
}
