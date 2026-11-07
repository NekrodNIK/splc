; ModuleID = 'test.spl'
source_filename = "test.spl"
target datalayout = "e-m:e-p270:32:32-p271:32:32-p272:64:64-i64:64-i128:128-f80:128-n8:16:32:64-S128"
target triple = "x86_64-unknown-linux-gnu"

define i64 @main() {
entry:
  %r = alloca i64, align 8
  store i64 0, ptr %r, align 8
  br i1 false, label %if.then, label %if.else

if.then:                                          ; preds = %entry
  store i64 1, ptr %r, align 8
  br label %if.cont

if.cont:                                          ; preds = %if.cont2, %if.then
  %0 = load i64, ptr %r, align 8
  ret i64 %0

if.else:                                          ; preds = %entry
  br i1 true, label %if.then1, label %if.else3

if.then1:                                         ; preds = %if.else
  store i64 2, ptr %r, align 8
  br label %if.cont2

if.cont2:                                         ; preds = %if.else3, %if.then1
  br label %if.cont

if.else3:                                         ; preds = %if.else
  store i64 3, ptr %r, align 8
  br label %if.cont2
}
