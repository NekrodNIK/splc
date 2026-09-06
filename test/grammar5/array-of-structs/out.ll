; ModuleID = 'spl'
source_filename = "spl"

%Point = type { i64, i64 }

define i64 @main() {
entry:
  %pts = alloca [2 x %Point], align 8
  store [2 x %Point] zeroinitializer, ptr %pts, align 4
  %subsaddr = getelementptr [2 x %Point], ptr %pts, i32 0, i64 0
  %fieldaddr = getelementptr inbounds nuw %Point, ptr %subsaddr, i32 0, i32 0
  store i64 1, ptr %fieldaddr, align 4
  %subsaddr1 = getelementptr [2 x %Point], ptr %pts, i32 0, i64 0
  %fieldaddr2 = getelementptr inbounds nuw %Point, ptr %subsaddr1, i32 0, i32 1
  store i64 2, ptr %fieldaddr2, align 4
  %subsaddr3 = getelementptr [2 x %Point], ptr %pts, i32 0, i64 1
  %fieldaddr4 = getelementptr inbounds nuw %Point, ptr %subsaddr3, i32 0, i32 0
  store i64 3, ptr %fieldaddr4, align 4
  %subsaddr5 = getelementptr [2 x %Point], ptr %pts, i32 0, i64 1
  %fieldaddr6 = getelementptr inbounds nuw %Point, ptr %subsaddr5, i32 0, i32 1
  store i64 4, ptr %fieldaddr6, align 4
  %subsaddr7 = getelementptr [2 x %Point], ptr %pts, i32 0, i64 0
  %fieldaddr8 = getelementptr inbounds nuw %Point, ptr %subsaddr7, i32 0, i32 0
  %fieldtmp = load i64, ptr %fieldaddr8, align 4
  %subsaddr9 = getelementptr [2 x %Point], ptr %pts, i32 0, i64 1
  %fieldaddr10 = getelementptr inbounds nuw %Point, ptr %subsaddr9, i32 0, i32 1
  %fieldtmp11 = load i64, ptr %fieldaddr10, align 4
  %addtmp = add i64 %fieldtmp, %fieldtmp11
  ret i64 %addtmp
}
