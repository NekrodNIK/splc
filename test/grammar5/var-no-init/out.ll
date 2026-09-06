; ModuleID = 'spl'
source_filename = "spl"

%Point = type { i64, i64 }

define i64 @main() {
entry:
  %p = alloca %Point, align 8
  store %Point zeroinitializer, ptr %p, align 4
  %arr = alloca [8 x i64], align 8
  store [8 x i64] zeroinitializer, ptr %arr, align 4
  %fieldaddr = getelementptr inbounds nuw %Point, ptr %p, i32 0, i32 0
  store i64 100, ptr %fieldaddr, align 4
  %fieldaddr1 = getelementptr inbounds nuw %Point, ptr %p, i32 0, i32 1
  store i64 200, ptr %fieldaddr1, align 4
  %subsaddr = getelementptr [8 x i64], ptr %arr, i32 0, i64 0
  %fieldaddr2 = getelementptr inbounds nuw %Point, ptr %p, i32 0, i32 0
  %fieldtmp = load i64, ptr %fieldaddr2, align 4
  store i64 %fieldtmp, ptr %subsaddr, align 4
  %subsaddr3 = getelementptr [8 x i64], ptr %arr, i32 0, i64 1
  %fieldaddr4 = getelementptr inbounds nuw %Point, ptr %p, i32 0, i32 1
  %fieldtmp5 = load i64, ptr %fieldaddr4, align 4
  store i64 %fieldtmp5, ptr %subsaddr3, align 4
  %subsaddr6 = getelementptr [8 x i64], ptr %arr, i32 0, i64 0
  %substmp = load i64, ptr %subsaddr6, align 4
  %subsaddr7 = getelementptr [8 x i64], ptr %arr, i32 0, i64 1
  %substmp8 = load i64, ptr %subsaddr7, align 4
  %addtmp = add i64 %substmp, %substmp8
  ret i64 %addtmp
}
