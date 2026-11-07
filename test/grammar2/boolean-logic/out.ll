; ModuleID = 'test.spl'
source_filename = "test.spl"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i64 @main() {
entry:
  %a = alloca i64, align 8
  store i64 1, ptr %a, align 8
  %b = alloca i64, align 8
  store i64 0, ptr %b, align 8
  %c = alloca i64, align 8
  %0 = load i64, ptr %a, align 8
  %1 = icmp ne i64 %0, 0
  %2 = xor i1 %1, true
  %3 = zext i1 %2 to i64
  %4 = load i64, ptr %b, align 8
  %5 = load i64, ptr %a, align 8
  %6 = icmp ne i64 %4, 0
  %7 = icmp ne i64 %5, 0
  %8 = and i1 %7, %6
  %9 = zext i1 %8 to i64
  %10 = icmp ne i64 %3, 0
  %11 = icmp ne i64 %9, 0
  %12 = or i1 %11, %10
  %13 = zext i1 %12 to i64
  store i64 %13, ptr %c, align 8
  %14 = load i64, ptr %c, align 8
  ret i64 %14
}
