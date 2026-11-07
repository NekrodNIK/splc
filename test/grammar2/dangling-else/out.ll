; ModuleID = 'test.spl'
source_filename = "test.spl"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i64 @main() {
entry:
  br i1 true, label %if.then, label %ifcont

if.then:                                          ; preds = %entry
  br i1 false, label %if.then1, label %if.else

ifcont:                                           ; preds = %if.cont, %entry
  ret i64 0

if.then1:                                         ; preds = %if.then
  ret i64 1

if.cont:                                          ; No predecessors!
  br label %ifcont

if.else:                                          ; preds = %if.then
  ret i64 2
}
