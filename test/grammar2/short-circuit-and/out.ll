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
  %r = alloca i64, align 8
  store i64 0, ptr %r, align 8
  %0 = load i64, ptr %y, align 8
  %1 = icmp eq i64 %0, 0
  %2 = zext i1 %1 to i64
  %3 = load i64, ptr %x, align 8
  %4 = icmp eq i64 %3, 0
  %5 = zext i1 %4 to i64
  %6 = icmp ne i64 %2, 0
  %7 = icmp ne i64 %5, 0
  %8 = and i1 %7, %6
  %9 = zext i1 %8 to i64
  %10 = icmp ne i64 %9, 0
  br i1 %10, label %if.then, label %ifcont

if.then:                                          ; preds = %entry
  store i64 1, ptr %r, align 8
  br label %ifcont

ifcont:                                           ; preds = %if.then, %entry
  %11 = load i64, ptr %r, align 8
  ret i64 %11
}
