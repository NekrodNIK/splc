; ModuleID = 'spl'
source_filename = "spl"

define i64 @main() {
entry:
  br i1 true, label %then, label %ifmerge

then:                                             ; preds = %entry
  br i1 false, label %then1, label %else

ifmerge:                                          ; preds = %ifmerge2, %entry
  ret i64 0

then1:                                            ; preds = %then
  ret i64 1
  br label %ifmerge2

ifmerge2:                                         ; preds = %else, %then1
  br label %ifmerge

else:                                             ; preds = %then
  ret i64 2
  br label %ifmerge2
}
