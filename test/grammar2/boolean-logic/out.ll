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
  br i1 %1, label %logic.rhs, label %logic.end

logic.rhs:                                        ; preds = %entry
  %2 = load i64, ptr %b, align 8
  %3 = icmp ne i64 %2, 0
  br label %logic.end

logic.end:                                        ; preds = %logic.rhs, %entry
  %4 = phi i1 [ true, %entry ], [ %3, %logic.rhs ]
  %5 = zext i1 %4 to i64
  %6 = icmp ne i64 %5, 0
  br i1 %6, label %logic.end2, label %logic.rhs1

logic.rhs1:                                       ; preds = %logic.end
  %7 = load i64, ptr %a, align 8
  %8 = icmp ne i64 %7, 0
  %9 = xor i1 %8, true
  %10 = zext i1 %9 to i64
  %11 = icmp ne i64 %10, 0
  br label %logic.end2

logic.end2:                                       ; preds = %logic.rhs1, %logic.end
  %12 = phi i1 [ false, %logic.end ], [ %11, %logic.rhs1 ]
  %13 = zext i1 %12 to i64
  store i64 %13, ptr %c, align 8
  %14 = load i64, ptr %c, align 8
  ret i64 %14
}
