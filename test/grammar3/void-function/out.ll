; ModuleID = 'spl'
source_filename = "spl"

define i64 @noop() {
entry:
  %x = alloca i64, align 8
  store i64 0, ptr %x, align 8
  ret i64 0
}

define i64 @main() {
entry:
  ret i64 42
}
