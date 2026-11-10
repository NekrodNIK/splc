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
  %0 = load i64, ptr %x, align 8
  %1 = icmp eq i64 %0, 0
  %2 = zext i1 %1 to i64
  %3 = icmp ne i64 %2, 0
  br i1 %3, label %logic.rhs, label %logic.end

if.then:                                          ; preds = %logic.end
  store i64 1, ptr %r, align 8
  br label %if.cont

if.cont:                                          ; preds = %if.then, %logic.end
  %4 = load i64, ptr %r, align 8
  ret i64 %4

logic.rhs:                                        ; preds = %entry
  %5 = load i64, ptr %y, align 8
  %6 = icmp eq i64 %5, 0
  %7 = zext i1 %6 to i64
  %8 = icmp ne i64 %7, 0
  br label %logic.end

logic.end:                                        ; preds = %logic.rhs, %entry
  %9 = phi i1 [ true, %entry ], [ %8, %logic.rhs ]
  %10 = zext i1 %9 to i64
  %11 = icmp ne i64 %10, 0
  br i1 %11, label %if.then, label %if.cont
}
