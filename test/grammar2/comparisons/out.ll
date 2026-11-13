; ModuleID = 'test.spl'
source_filename = "test.spl"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i64 @main() {
entry:
  %cmp1 = alloca i64, align 8
  store i64 0, ptr %cmp1, align 8
  %cmp2 = alloca i64, align 8
  store i64 1, ptr %cmp2, align 8
  %cmp3 = alloca i64, align 8
  store i64 1, ptr %cmp3, align 8
  %cmp4 = alloca i64, align 8
  store i64 0, ptr %cmp4, align 8
  %cmp5 = alloca i64, align 8
  store i64 1, ptr %cmp5, align 8
  %cmp6 = alloca i64, align 8
  store i64 0, ptr %cmp6, align 8
  %0 = load i64, ptr %cmp6, align 8
  %1 = load i64, ptr %cmp5, align 8
  %2 = load i64, ptr %cmp4, align 8
  %3 = load i64, ptr %cmp3, align 8
  %4 = load i64, ptr %cmp2, align 8
  %5 = load i64, ptr %cmp1, align 8
  %6 = add i64 %5, %4
  %7 = add i64 %6, %3
  %8 = add i64 %7, %2
  %9 = add i64 %8, %1
  %10 = add i64 %9, %0
  ret i64 %10
}
