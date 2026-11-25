; ModuleID = 'test.spl'
source_filename = "test.spl"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i64 @noop() {
entry:
  ret i64 0
}

declare i64 @foo(i64)

define i64 @main() {
entry:
  %a = alloca i64, align 8
  %0 = call i64 @noop()
  %1 = call i64 @foo(i64 %0)
  store i64 %1, ptr %a, align 8
  %2 = load i64, ptr %a, align 8
  ret i64 %2
}
