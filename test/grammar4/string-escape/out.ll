; ModuleID = 'spl'
source_filename = "spl"

@.str.0 = private constant [14 x i8] c"hello\0Aworld\09!\00"
@.str.1 = private constant [13 x i8] c"quote \22 here\00"
@.str.2 = private constant [11 x i8] c"back\\slash\00"

define i64 @main() {
entry:
  %s = alloca ptr, align 8
  store ptr @.str.0, ptr %s, align 8
  %t = alloca ptr, align 8
  store ptr @.str.1, ptr %t, align 8
  %u = alloca ptr, align 8
  store ptr @.str.2, ptr %u, align 8
  ret i64 0
}
