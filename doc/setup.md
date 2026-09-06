# Toolchain Setup

This document covers the tools you need to build and run your compiler for
this course: the LLVM/Clang toolchain, the provided runtime library, and how
they fit into the test workflow.

## Requirements

| Tool | Minimum version | Needed for |
| ---- | --------------- | ---------- |
| LLVM / Clang | 19+ | Compiling generated LLVM IR to executables, linking with runtime |
| Python | 3.9+ | Test harness (`test/run_tests.py`) |
| (optional) CMake | 3.16+ | Building the provided runtime library |

GCC works as an alternative to Clang for compiling the runtime library, but
**Clang is required** to compile the LLVM IR your compiler emits (GCC cannot
read LLVM IR).

## Installing LLVM and Clang

### Linux (Debian/Ubuntu)

```bash
sudo apt install llvm-dev clang

# Verify installation
llvm-config --version   # Should be 19 or later
clang --version
```

### Linux (Fedora)

```bash
sudo dnf install llvm-devel clang
```

### macOS (Homebrew)

```bash
brew install llvm

# LLVM tools are keg-only; add them to your PATH:
export PATH="$(brew --prefix llvm)/bin:$PATH"
```

### Windows

Download the LLVM installer from https://releases.llvm.org/ or use:

```bash
choco install llvm
```

## Compiling and Running Generated LLVM IR

The overall flow is:

1. Your compiler reads a `.spl` source file and produces LLVM IR text (`output.ll`).
2. Clang compiles the IR to a native executable, optionally linking with the
   runtime library.
3. The executable runs and its exit code / stdout are compared by the test harness.

```bash
# Step 1: Your compiler produces LLVM IR (output.ll)
./splc -o output.ll source.spl

# Step 2a: Compile IR to executable without the runtime
clang output.ll -o program

# Step 2b: Compile IR and link with the runtime library (grammar 3+)
clang output.ll -L build/libruntime -lsplruntime -o program

# Step 3: Run
./program
```

> **Note about `lli`**: You can also run LLVM IR directly with `lli`, but the
> test harness expects a compiled executable. Use `clang` for production runs.

## Fitting into the test harness

The test harness needs a way to (a) build your compiler and (b) turn a `.spl`
file into a runnable executable. This is configured in `test/config.json`
(see [`test/README.md`](../test/README.md) for the full format).

The `compile` stage in the config must produce an executable at `{exe}`. A
typical approach:

```json
"compile": {
  "cmd": ["bash", "-c",
    "{root}/build/splc -g {grammar} -o /tmp/out.ll {input} && " +
    "clang /tmp/out.ll -L{root}/build/libruntime -lsplruntime -o {exe} -Wno-override-module"]
}
```

Adjust the `splc` invocation to match your own compiler's CLI, and drop the
runtime library flags for grammars 1–2 if you are not using it.

## Building the runtime library

The runtime library (`libruntime/`) is a small C library providing print
helpers for grammars 3+. See [`doc/runtime.md`](runtime.md) for its API.

```bash
cmake -S libruntime -B build/libruntime
cmake --build build/libruntime
# produces build/libruntime/libsplruntime.a
```

If you don't use CMake, you can compile it directly:

```bash
cc -c libruntime/spl_runtime.c -o spl_runtime.o
ar rcs libsplruntime.a spl_runtime.o
```

## Verifying your setup

Before implementing anything, make sure the toolchain works end to end with a
hand-written IR file:

```bash
cat > hello.ll <<'EOF'
declare void @println()

define i64 @main() {
entry:
  call void @println()
  ret i64 0
}
EOF

clang hello.ll -L build/libruntime -lsplruntime -o hello
./hello
```

If this prints an empty line and exits 0, your toolchain is ready.