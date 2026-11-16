; ModuleID = 'test.spl'
source_filename = "test.spl"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i64 @fib(i64 %0) {
entry:
  %n = alloca i64, align 8
  store i64 %0, ptr %n, align 8
  %1 = load i64, ptr %n, align 8
  %2 = icmp sle i64 %1, 1
  %3 = zext i1 %2 to i64
  %4 = icmp ne i64 %3, 0
  br i1 %4, label %if.then, label %if.cont

if.then:                                          ; preds = %entry
  %5 = load i64, ptr %n, align 8
  ret i64 %5

if.cont:                                          ; preds = %entry
  %6 = load i64, ptr %n, align 8
  %7 = sub i64 %6, 2
  %8 = call i64 @fib(i64 %7)
  %9 = load i64, ptr %n, align 8
  %10 = sub i64 %9, 1
  %11 = call i64 @fib(i64 %10)
  %12 = add i64 %11, %8
  ret i64 %12
}

declare i64 @getchar()

define i64 @main() {
entry:
  %result = alloca i64, align 8
  %0 = call i64 @fib(i64 10)
  store i64 %0, ptr %result, align 8
  %1 = load i64, ptr %result, align 8
  ret i64 %1
}
