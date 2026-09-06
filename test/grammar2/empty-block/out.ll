; ModuleID = 'spl'
source_filename = "spl"

define i64 @main() {
entry:
  %x = alloca i64, align 8
  store i64 1, ptr %x, align 8
  br label %while_header

while_header:                                     ; preds = %while_body, %entry
  %x1 = load i64, ptr %x, align 8
  %whilecond = icmp ne i64 %x1, 0
  br i1 %whilecond, label %while_body, label %while_end

while_body:                                       ; preds = %while_header
  br label %while_header

while_end:                                        ; preds = %while_header
  ret i64 0
}
