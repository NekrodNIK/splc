; ModuleID = 'spl'
source_filename = "spl"

define i64 @double(i64 %0) {
entry:
  %x = alloca i64, align 8
  store i64 %0, ptr %x, align 8
  %x1 = load i64, ptr %x, align 8
  %multmp = mul i64 %x1, 2
  ret i64 %multmp
}

define i64 @main() {
entry:
  %calltmp = call i64 @double(i64 21)
  ret i64 %calltmp
}
