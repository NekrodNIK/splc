; ModuleID = 'spl'
source_filename = "spl"

define i64 @main() {
entry:
  br i1 true, label %then, label %else

then:                                             ; preds = %entry
  ret i64 1
  br label %ifmerge

ifmerge:                                          ; preds = %ifmerge2, %then
  ret i64 0

else:                                             ; preds = %entry
  br i1 false, label %then1, label %else3

then1:                                            ; preds = %else
  ret i64 2
  br label %ifmerge2

ifmerge2:                                         ; preds = %else3, %then1
  br label %ifmerge

else3:                                            ; preds = %else
  ret i64 3
  br label %ifmerge2
}
