; ModuleID = 'spl'
source_filename = "spl"

@.str.0 = private constant [6 x i8] c"hello\00"
@.str.1 = private constant [6 x i8] c"hello\00"

define i64 @main() {
entry:
  %a = alloca ptr, align 8
  store ptr @.str.0, ptr %a, align 8
  %b = alloca ptr, align 8
  store ptr @.str.1, ptr %b, align 8
  %a1 = load ptr, ptr %a, align 8
  %b2 = load ptr, ptr %b, align 8
  %strcmp = call i32 @strcmp(ptr %a1, ptr %b2)
  %strcmptmp = icmp eq i32 %strcmp, 0
  br i1 %strcmptmp, label %then, label %else

then:                                             ; preds = %entry
  ret i64 1
  br label %ifmerge

ifmerge:                                          ; preds = %else, %then
  ret i64 0

else:                                             ; preds = %entry
  ret i64 0
  br label %ifmerge
}

declare i32 @strcmp(ptr, ptr)
