; ModuleID = 'spl'
source_filename = "spl"

%Outer = type { %Inner, i64 }
%Inner = type { i64 }

define i64 @main() {
entry:
  %o = alloca %Outer, align 8
  store %Outer zeroinitializer, ptr %o, align 4
  %fieldaddr = getelementptr inbounds nuw %Outer, ptr %o, i32 0, i32 0
  %fieldaddr1 = getelementptr inbounds nuw %Inner, ptr %fieldaddr, i32 0, i32 0
  store i64 42, ptr %fieldaddr1, align 4
  %fieldaddr2 = getelementptr inbounds nuw %Outer, ptr %o, i32 0, i32 1
  store i64 7, ptr %fieldaddr2, align 4
  %fieldaddr3 = getelementptr inbounds nuw %Outer, ptr %o, i32 0, i32 0
  %fieldaddr4 = getelementptr inbounds nuw %Inner, ptr %fieldaddr3, i32 0, i32 0
  %fieldtmp = load i64, ptr %fieldaddr4, align 4
  %fieldaddr5 = getelementptr inbounds nuw %Outer, ptr %o, i32 0, i32 1
  %fieldtmp6 = load i64, ptr %fieldaddr5, align 4
  %addtmp = add i64 %fieldtmp, %fieldtmp6
  ret i64 %addtmp
}
