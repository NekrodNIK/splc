; ModuleID = 'test.spl'
source_filename = "test.spl"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i64 @main() {
entry:
  %i = alloca i64, align 8
  store i64 0, ptr %i, align 8
  %x = alloca i64, align 8
  store i64 0, ptr %x, align 8
  br label %while.cond

while.cond:                                       ; preds = %if.cont, %if.then, %entry
  %0 = load i64, ptr %i, align 8
  %1 = icmp slt i64 %0, 5
  %2 = zext i1 %1 to i64
  %3 = icmp ne i64 %2, 0
  br i1 %3, label %while.body, label %while.end

while.body:                                       ; preds = %while.cond
  %4 = load i64, ptr %i, align 8
  %5 = add i64 %4, 1
  store i64 %5, ptr %i, align 8
  %6 = load i64, ptr %i, align 8
  %7 = icmp sgt i64 %6, 3
  %8 = zext i1 %7 to i64
  %9 = icmp ne i64 %8, 0
  br i1 %9, label %if.then, label %if.cont

while.end:                                        ; preds = %while.cond
  %10 = load i64, ptr %x, align 8
  ret i64 %10

if.then:                                          ; preds = %while.body
  br label %while.cond

if.cont:                                          ; preds = %while.body
  %11 = load i64, ptr %x, align 8
  %12 = add i64 %11, 1
  store i64 %12, ptr %x, align 8
  br label %while.cond
}
