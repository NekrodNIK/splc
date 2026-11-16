; ModuleID = 'test.spl'
source_filename = "test.spl"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i64 @add(i64 %0, i64 %1) {
entry:
  %a = alloca i64, align 8
  store i64 %0, ptr %a, align 8
  %b = alloca i64, align 8
  store i64 %1, ptr %b, align 8
  %result = alloca i64, align 8
  %2 = load i64, ptr %b, align 8
  %3 = load i64, ptr %a, align 8
  %4 = add i64 %3, %2
  store i64 %4, ptr %result, align 8
  %5 = load i64, ptr %result, align 8
  ret i64 %5
}

define i64 @main() {
entry:
  %0 = call i64 @add(i64 2, i64 3)
  ret i64 %0
}
