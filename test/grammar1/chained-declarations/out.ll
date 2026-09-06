; ModuleID = 'spl'
source_filename = "spl"

define i64 @main() {
entry:
  %x = alloca i64, align 8
  store i64 5, ptr %x, align 8
  %y = alloca i64, align 8
  %x1 = load i64, ptr %x, align 8
  store i64 %x1, ptr %y, align 8
  %y2 = load i64, ptr %y, align 8
  ret i64 %y2
}
