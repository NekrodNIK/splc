; ModuleID = 'spl'
source_filename = "spl"

declare i64 @putchar(i8)

declare i64 @exit(i64)

define i64 @main() {
entry:
  %r = alloca i64, align 8
  %calltmp = call i64 @putchar(i8 65)
  store i64 %calltmp, ptr %r, align 4
  %code = alloca i64, align 8
  store i64 0, ptr %code, align 4
  %code1 = load i64, ptr %code, align 4
  ret i64 %code1
}
