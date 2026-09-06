; ModuleID = 'spl'
source_filename = "spl"

define i64 @foo() {
entry:
  %calltmp = call i64 @bar()
  ret i64 0
}

declare i64 @bar()
