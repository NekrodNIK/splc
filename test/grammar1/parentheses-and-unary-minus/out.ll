; ModuleID = 'spl'
source_filename = "spl"

define i64 @main() {
entry:
  %result = alloca i64, align 8
  store i64 0, ptr %result, align 8
  ret i64 0
}
