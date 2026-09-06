; ModuleID = 'spl'
source_filename = "spl"

declare i64 @putchar(i64)

define i64 @main() {
entry:
  %a = alloca i64, align 8
  %calltmp = call i64 @putchar(i64 72)
  store i64 %calltmp, ptr %a, align 8
  %b = alloca i64, align 8
  %calltmp1 = call i64 @putchar(i64 105)
  store i64 %calltmp1, ptr %b, align 8
  ret i64 0
}
