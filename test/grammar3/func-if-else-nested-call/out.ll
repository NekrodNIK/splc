; ModuleID = 'test.spl'
source_filename = "test.spl"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i64 @max(i64 %0, i64 %1) {
entry:
  %a = alloca i64, align 8
  store i64 %0, ptr %a, align 8
  %b = alloca i64, align 8
  store i64 %1, ptr %b, align 8
  %2 = load i64, ptr %b, align 8
  %3 = load i64, ptr %a, align 8
  %4 = icmp sgt i64 %3, %2
  %5 = zext i1 %4 to i64
  %6 = icmp ne i64 %5, 0
  br i1 %6, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  %7 = load i64, ptr %a, align 8
  ret i64 %7

if.else:                                          ; preds = %entry
  %8 = load i64, ptr %b, align 8
  ret i64 %8

if.cont:                                          ; No predecessors!
  ret i64 0
}

define i64 @main() {
entry:
  %m = alloca i64, align 8
  %0 = call i64 @max(i64 10, i64 20)
  store i64 %0, ptr %m, align 8
  %1 = load i64, ptr %m, align 8
  ret i64 %1
}
