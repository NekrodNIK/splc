; ModuleID = 'test.spl'
source_filename = "test.spl"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i64 @main() {
entry:
  %x = alloca i64, align 8
  store i64 1, ptr %x, align 8
  %y = alloca i64, align 8
  store i64 0, ptr %y, align 8
  %0 = load i64, ptr %x, align 8
  %1 = icmp eq i64 %0, 1
  %2 = zext i1 %1 to i64
  %3 = icmp ne i64 %2, 0
  br i1 %3, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  store i64 2, ptr %y, align 8
  br label %if.cont

if.cont:                                          ; preds = %if.else, %if.then
  %4 = load i64, ptr %y, align 8
  ret i64 %4

if.else:                                          ; preds = %entry
  store i64 3, ptr %y, align 8
  br label %if.cont
}
