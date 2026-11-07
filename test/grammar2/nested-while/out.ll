; ModuleID = 'test.spl'
source_filename = "test.spl"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i64 @main() {
entry:
  %i = alloca i64, align 8
  store i64 0, ptr %i, align 8
  br label %while.cond

while.cond:                                       ; preds = %while.end3, %entry
  %0 = load i64, ptr %i, align 8
  %1 = icmp slt i64 %0, 10
  %2 = zext i1 %1 to i64
  %3 = icmp ne i64 %2, 0
  br i1 %3, label %while.body, label %while.end

while.body:                                       ; preds = %while.cond
  %j = alloca i64, align 8
  store i64 0, ptr %j, align 8
  br label %while.cond1

while.end:                                        ; preds = %while.cond
  %4 = load i64, ptr %i, align 8
  ret i64 %4

while.cond1:                                      ; preds = %while.body2, %while.body
  %5 = load i64, ptr %j, align 8
  %6 = icmp slt i64 %5, 10
  %7 = zext i1 %6 to i64
  %8 = icmp ne i64 %7, 0
  br i1 %8, label %while.body2, label %while.end3

while.body2:                                      ; preds = %while.cond1
  %9 = load i64, ptr %j, align 8
  %10 = add i64 %9, 1
  store i64 %10, ptr %j, align 8
  br label %while.cond1

while.end3:                                       ; preds = %while.cond1
  %11 = load i64, ptr %i, align 8
  %12 = add i64 %11, 1
  store i64 %12, ptr %i, align 8
  br label %while.cond
}
