; ModuleID = 'test.spl'
source_filename = "test.spl"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i64 @main() {
entry:
  %x = alloca i64, align 8
  store i64 0, ptr %x, align 8
  br label %while.cond

while.cond:                                       ; preds = %if.cont, %entry
  %0 = load i64, ptr %x, align 8
  %1 = icmp slt i64 %0, 10
  %2 = zext i1 %1 to i64
  %3 = icmp ne i64 %2, 0
  br i1 %3, label %while.body, label %while.end

while.body:                                       ; preds = %while.cond
  %4 = load i64, ptr %x, align 8
  %5 = icmp slt i64 %4, 5
  %6 = zext i1 %5 to i64
  %7 = icmp ne i64 %6, 0
  br i1 %7, label %if.then, label %if.else

while.end:                                        ; preds = %if.else, %while.cond
  %8 = load i64, ptr %x, align 8
  ret i64 %8

if.then:                                          ; preds = %while.body
  %9 = load i64, ptr %x, align 8
  %10 = add i64 %9, 1
  store i64 %10, ptr %x, align 8
  br label %if.cont

if.cont:                                          ; preds = %if.then
  br label %while.cond

if.else:                                          ; preds = %while.body
  br label %while.end
}
