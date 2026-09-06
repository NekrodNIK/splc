; ModuleID = 'spl'
source_filename = "spl"

define i64 @main() {
entry:
  %x = alloca i64, align 8
  store i64 1, ptr %x, align 4
  %y = alloca i1, align 1
  %x1 = load i64, ptr %x, align 4
  %trunctmp = trunc i64 %x1 to i1
  store i1 %trunctmp, ptr %y, align 1
  %y2 = load i1, ptr %y, align 1
  br i1 %y2, label %then, label %else

then:                                             ; preds = %entry
  ret i64 1
  br label %ifmerge

ifmerge:                                          ; preds = %else, %then
  ret i64 0

else:                                             ; preds = %entry
  ret i64 0
  br label %ifmerge
}
