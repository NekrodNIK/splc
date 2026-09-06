; ModuleID = 'spl'
source_filename = "spl"

@.str.0 = private constant [6 x i8] c"hello\00"
@.str.1 = private constant [6 x i8] c"world\00"

define i64 @main() {
entry:
  %s = alloca ptr, align 8
  store ptr @.str.0, ptr %s, align 8
  %msg = alloca ptr, align 8
  store ptr @.str.1, ptr %msg, align 8
  ret i64 0
}
