; ModuleID = 'spl'
source_filename = "spl"

define i64 @noop() {
entry:
  ret i64 0
}

declare i64 @foo(i64)

define i64 @main() {
entry:
  %a = alloca i64, align 8
  %calltmp = call i64 @noop()
  %calltmp1 = call i64 @foo(i64 %calltmp)
  store i64 %calltmp1, ptr %a, align 8
  ret i64 0
}
