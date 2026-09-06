; ModuleID = 'spl'
source_filename = "spl"

define i64 @main() {
entry:
  %x = alloca i8, align 1
  store i8 42, ptr %x, align 1
  %y = alloca i16, align 2
  %x1 = load i8, ptr %x, align 1
  %sexttmp = sext i8 %x1 to i16
  store i16 %sexttmp, ptr %y, align 2
  %z = alloca i32, align 4
  %y2 = load i16, ptr %y, align 2
  %sexttmp3 = sext i16 %y2 to i32
  store i32 %sexttmp3, ptr %z, align 4
  %w = alloca i64, align 8
  %z4 = load i32, ptr %z, align 4
  %sexttmp5 = sext i32 %z4 to i64
  store i64 %sexttmp5, ptr %w, align 4
  %w6 = load i64, ptr %w, align 4
  ret i64 %w6
}
