; ModuleID = 'spl'
source_filename = "spl"

define i64 @main() {
entry:
  %x = alloca i1, align 1
  store i1 true, ptr %x, align 1
  %y = alloca i64, align 8
  %x1 = load i1, ptr %x, align 1
  %zexttmp = zext i1 %x1 to i64
  store i64 %zexttmp, ptr %y, align 4
  %y2 = load i64, ptr %y, align 4
  ret i64 %y2
}
