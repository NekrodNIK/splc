; ModuleID = 'spl'
source_filename = "spl"

define i64 @is_even(i64 %0) {
entry:
  %n = alloca i64, align 8
  store i64 %0, ptr %n, align 8
  %n1 = load i64, ptr %n, align 8
  %cmptmp = icmp eq i64 %n1, 0
  %zexttmp = zext i1 %cmptmp to i64
  %ifcond = icmp ne i64 %zexttmp, 0
  br i1 %ifcond, label %then, label %ifmerge

then:                                             ; preds = %entry
  ret i64 1
  br label %ifmerge

ifmerge:                                          ; preds = %then, %entry
  %n2 = load i64, ptr %n, align 8
  %subtmp = sub i64 %n2, 1
  %calltmp = call i64 @is_odd(i64 %subtmp)
  ret i64 %calltmp
}

define i64 @is_odd(i64 %0) {
entry:
  %n = alloca i64, align 8
  store i64 %0, ptr %n, align 8
  %n1 = load i64, ptr %n, align 8
  %cmptmp = icmp eq i64 %n1, 0
  %zexttmp = zext i1 %cmptmp to i64
  %ifcond = icmp ne i64 %zexttmp, 0
  br i1 %ifcond, label %then, label %ifmerge

then:                                             ; preds = %entry
  ret i64 0
  br label %ifmerge

ifmerge:                                          ; preds = %then, %entry
  %n2 = load i64, ptr %n, align 8
  %subtmp = sub i64 %n2, 1
  %calltmp = call i64 @is_even(i64 %subtmp)
  ret i64 %calltmp
}

define i64 @main() {
entry:
  %calltmp = call i64 @is_even(i64 4)
  ret i64 %calltmp
}
