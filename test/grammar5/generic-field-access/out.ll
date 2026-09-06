; ModuleID = 'spl'
source_filename = "spl"

%Rectangle = type { i64, i64 }

define i64 @main() {
entry:
  %r = alloca %Rectangle, align 8
  store %Rectangle zeroinitializer, ptr %r, align 4
  %fieldaddr = getelementptr inbounds nuw %Rectangle, ptr %r, i32 0, i32 0
  store i64 6, ptr %fieldaddr, align 4
  %fieldaddr1 = getelementptr inbounds nuw %Rectangle, ptr %r, i32 0, i32 1
  store i64 7, ptr %fieldaddr1, align 4
  %area = alloca i64, align 8
  store i64 0, ptr %area, align 4
  %fieldaddr2 = getelementptr inbounds nuw %Rectangle, ptr %r, i32 0, i32 0
  %fieldtmp = load i64, ptr %fieldaddr2, align 4
  %fieldaddr3 = getelementptr inbounds nuw %Rectangle, ptr %r, i32 0, i32 1
  %fieldtmp4 = load i64, ptr %fieldaddr3, align 4
  %multmp = mul i64 %fieldtmp, %fieldtmp4
  store i64 %multmp, ptr %area, align 4
  %area5 = load i64, ptr %area, align 4
  ret i64 %area5
}
