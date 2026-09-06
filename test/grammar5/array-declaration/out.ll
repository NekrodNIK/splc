; ModuleID = 'spl'
source_filename = "spl"

define i64 @main() {
entry:
  %arr = alloca [10 x i64], align 8
  store [10 x i64] zeroinitializer, ptr %arr, align 4
  %subsaddr = getelementptr [10 x i64], ptr %arr, i32 0, i64 0
  store i64 1, ptr %subsaddr, align 4
  %subsaddr1 = getelementptr [10 x i64], ptr %arr, i32 0, i64 1
  store i64 2, ptr %subsaddr1, align 4
  %subsaddr2 = getelementptr [10 x i64], ptr %arr, i32 0, i64 2
  store i64 3, ptr %subsaddr2, align 4
  %sum = alloca i64, align 8
  %subsaddr3 = getelementptr [10 x i64], ptr %arr, i32 0, i64 0
  %substmp = load i64, ptr %subsaddr3, align 4
  %subsaddr4 = getelementptr [10 x i64], ptr %arr, i32 0, i64 1
  %substmp5 = load i64, ptr %subsaddr4, align 4
  %addtmp = add i64 %substmp, %substmp5
  %subsaddr6 = getelementptr [10 x i64], ptr %arr, i32 0, i64 2
  %substmp7 = load i64, ptr %subsaddr6, align 4
  %addtmp8 = add i64 %addtmp, %substmp7
  store i64 %addtmp8, ptr %sum, align 4
  %sum9 = load i64, ptr %sum, align 4
  ret i64 %sum9
}
