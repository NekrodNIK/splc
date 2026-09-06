; ModuleID = 'spl'
source_filename = "spl"

define i64 @main() {
entry:
  %arr = alloca [5 x i64], align 8
  store [5 x i64] zeroinitializer, ptr %arr, align 4
  %i = alloca i64, align 8
  store i64 0, ptr %i, align 4
  store i64 0, ptr %i, align 4
  %subsaddr = getelementptr [5 x i64], ptr %arr, i32 0, i64 0
  store i64 10, ptr %subsaddr, align 4
  %subsaddr1 = getelementptr [5 x i64], ptr %arr, i32 0, i64 1
  store i64 20, ptr %subsaddr1, align 4
  %subsaddr2 = getelementptr [5 x i64], ptr %arr, i32 0, i64 2
  store i64 30, ptr %subsaddr2, align 4
  %subsaddr3 = getelementptr [5 x i64], ptr %arr, i32 0, i64 3
  store i64 40, ptr %subsaddr3, align 4
  %subsaddr4 = getelementptr [5 x i64], ptr %arr, i32 0, i64 4
  store i64 50, ptr %subsaddr4, align 4
  %result = alloca i64, align 8
  %subsaddr5 = getelementptr [5 x i64], ptr %arr, i32 0, i64 2
  %substmp = load i64, ptr %subsaddr5, align 4
  store i64 %substmp, ptr %result, align 4
  %result6 = load i64, ptr %result, align 4
  ret i64 %result6
}
