; ModuleID = 'spl'
source_filename = "spl"

define i64 @fib(i64 %0) {
entry:
  %n = alloca i64, align 8
  store i64 %0, ptr %n, align 8
  %n1 = load i64, ptr %n, align 8
  %cmptmp = icmp sle i64 %n1, 1
  %zexttmp = zext i1 %cmptmp to i64
  %ifcond = icmp ne i64 %zexttmp, 0
  br i1 %ifcond, label %then, label %ifmerge

then:                                             ; preds = %entry
  %n2 = load i64, ptr %n, align 8
  ret i64 %n2
  br label %ifmerge

ifmerge:                                          ; preds = %then, %entry
  %n3 = load i64, ptr %n, align 8
  %subtmp = sub i64 %n3, 1
  %calltmp = call i64 @fib(i64 %subtmp)
  %n4 = load i64, ptr %n, align 8
  %subtmp5 = sub i64 %n4, 2
  %calltmp6 = call i64 @fib(i64 %subtmp5)
  %addtmp = add i64 %calltmp, %calltmp6
  ret i64 %addtmp
}

declare i64 @getchar()

define i64 @main() {
entry:
  %result = alloca i64, align 8
  %calltmp = call i64 @fib(i64 10)
  store i64 %calltmp, ptr %result, align 8
  %c = alloca i64, align 8
  %calltmp1 = call i64 @getchar()
  store i64 %calltmp1, ptr %c, align 8
  %result2 = load i64, ptr %result, align 8
  ret i64 %result2
}
