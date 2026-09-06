; ModuleID = 'spl'
source_filename = "spl"

define i64 @main() {
entry:
  %x = alloca i64, align 8
  store i64 10, ptr %x, align 8
  %x1 = load i64, ptr %x, align 8
  %divtmp = sdiv i64 %x1, 2
  ret i64 %divtmp
}
