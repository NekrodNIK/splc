; ModuleID = 'spl'
source_filename = "spl"

define i64 @max(i64 %0, i64 %1) {
entry:
  %a = alloca i64, align 8
  store i64 %0, ptr %a, align 4
  %b = alloca i64, align 8
  store i64 %1, ptr %b, align 4
  %a1 = load i64, ptr %a, align 4
  %b2 = load i64, ptr %b, align 4
  %cmptmp = icmp sgt i64 %a1, %b2
  br i1 %cmptmp, label %then, label %else

then:                                             ; preds = %entry
  %a3 = load i64, ptr %a, align 4
  ret i64 %a3
  br label %ifmerge

ifmerge:                                          ; preds = %else, %then
  ret i64 0

else:                                             ; preds = %entry
  %b4 = load i64, ptr %b, align 4
  ret i64 %b4
  br label %ifmerge
}

define i64 @main() {
entry:
  %m = alloca i64, align 8
  %calltmp = call i64 @max(i64 7, i64 12)
  store i64 %calltmp, ptr %m, align 4
  %m1 = load i64, ptr %m, align 4
  ret i64 %m1
}
