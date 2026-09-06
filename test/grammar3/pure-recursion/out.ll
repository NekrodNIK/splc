; ModuleID = 'spl'
source_filename = "spl"

define i64 @fact(i64 %0) {
entry:
  %n = alloca i64, align 8
  store i64 %0, ptr %n, align 8
  %n1 = load i64, ptr %n, align 8
  %cmptmp = icmp sle i64 %n1, 1
  %zexttmp = zext i1 %cmptmp to i64
  %ifcond = icmp ne i64 %zexttmp, 0
  br i1 %ifcond, label %then, label %ifmerge

then:                                             ; preds = %entry
  ret i64 1
  br label %ifmerge

ifmerge:                                          ; preds = %then, %entry
  %n2 = load i64, ptr %n, align 8
  %n3 = load i64, ptr %n, align 8
  %subtmp = sub i64 %n3, 1
  %calltmp = call i64 @fact(i64 %subtmp)
  %multmp = mul i64 %n2, %calltmp
  ret i64 %multmp
}
