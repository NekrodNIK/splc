; ModuleID = 'spl'
source_filename = "spl"

define i64 @main() {
entry:
  %matrix = alloca [2 x [3 x i64]], align 8
  store [2 x [3 x i64]] zeroinitializer, ptr %matrix, align 4
  %subsaddr = getelementptr [2 x [3 x i64]], ptr %matrix, i32 0, i64 0
  %subsaddr1 = getelementptr [3 x i64], ptr %subsaddr, i32 0, i64 0
  store i64 1, ptr %subsaddr1, align 4
  %subsaddr2 = getelementptr [2 x [3 x i64]], ptr %matrix, i32 0, i64 0
  %subsaddr3 = getelementptr [3 x i64], ptr %subsaddr2, i32 0, i64 1
  store i64 2, ptr %subsaddr3, align 4
  %subsaddr4 = getelementptr [2 x [3 x i64]], ptr %matrix, i32 0, i64 0
  %subsaddr5 = getelementptr [3 x i64], ptr %subsaddr4, i32 0, i64 2
  store i64 3, ptr %subsaddr5, align 4
  %subsaddr6 = getelementptr [2 x [3 x i64]], ptr %matrix, i32 0, i64 1
  %subsaddr7 = getelementptr [3 x i64], ptr %subsaddr6, i32 0, i64 0
  store i64 4, ptr %subsaddr7, align 4
  %subsaddr8 = getelementptr [2 x [3 x i64]], ptr %matrix, i32 0, i64 1
  %subsaddr9 = getelementptr [3 x i64], ptr %subsaddr8, i32 0, i64 1
  store i64 5, ptr %subsaddr9, align 4
  %subsaddr10 = getelementptr [2 x [3 x i64]], ptr %matrix, i32 0, i64 1
  %subsaddr11 = getelementptr [3 x i64], ptr %subsaddr10, i32 0, i64 2
  store i64 6, ptr %subsaddr11, align 4
  %sum = alloca i64, align 8
  %subsaddr12 = getelementptr [2 x [3 x i64]], ptr %matrix, i32 0, i64 0
  %subsaddr13 = getelementptr [3 x i64], ptr %subsaddr12, i32 0, i64 0
  %substmp = load i64, ptr %subsaddr13, align 4
  %subsaddr14 = getelementptr [2 x [3 x i64]], ptr %matrix, i32 0, i64 0
  %subsaddr15 = getelementptr [3 x i64], ptr %subsaddr14, i32 0, i64 1
  %substmp16 = load i64, ptr %subsaddr15, align 4
  %addtmp = add i64 %substmp, %substmp16
  %subsaddr17 = getelementptr [2 x [3 x i64]], ptr %matrix, i32 0, i64 1
  %subsaddr18 = getelementptr [3 x i64], ptr %subsaddr17, i32 0, i64 2
  %substmp19 = load i64, ptr %subsaddr18, align 4
  %addtmp20 = add i64 %addtmp, %substmp19
  store i64 %addtmp20, ptr %sum, align 4
  %sum21 = load i64, ptr %sum, align 4
  ret i64 %sum21
}
