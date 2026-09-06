; ModuleID = 'spl'
source_filename = "spl"

define i64 @main() {
entry:
  %a = alloca i1, align 1
  store i1 true, ptr %a, align 1
  %b = alloca i1, align 1
  store i1 false, ptr %b, align 1
  %cmp = alloca i1, align 1
  store i1 true, ptr %cmp, align 1
  ret i64 0
}
