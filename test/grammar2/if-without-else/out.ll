; ModuleID = 'spl'
source_filename = "spl"

define i64 @main() {
entry:
  br i1 true, label %then, label %ifmerge

then:                                             ; preds = %entry
  ret i64 42
  br label %ifmerge

ifmerge:                                          ; preds = %then, %entry
  ret i64 0
}
