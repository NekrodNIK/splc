# Compiler construction

This repository is the **starter code** for a compiler course where each student
builds their own compiler frontend for a small language with LLVM backend.

You may implement your compiler in **any language you choose**. In each consecutive
assignment, the language grammar grows in features, and you extend your compiler
to support the new syntax and semantics.

## Repository contents

| Path | Description |
| ---- | ----------- |
| [`plan.md`](plan.md) | Full course plan and grammar descriptions |
| [`doc/grammar1.md`](doc/grammar1.md) | Reference documentation for grammar version 1 |
| [`doc/grammar1.g4`](doc/grammar1.g4) | ANTLR v4 grammar file for grammar version 1 (used by the fuzzer) |
| [`doc/grammar2.md`](doc/grammar2.md) | Reference documentation for grammar version 2 |
| [`doc/grammar2.g4`](doc/grammar2.g4) | ANTLR v4 grammar file for grammar version 2 |
| ... | ... (same pattern for grammars 3-5) |
| [`doc/setup.md`](doc/setup.md) | Toolchain setup: LLVM/Clang installation, compiling IR, linking with the runtime |
| [`doc/runtime.md`](doc/runtime.md) | Runtime library documentation (print, println, strings) |
| [`doc/error-handling.md`](doc/error-handling.md) | Error handling strategy (lexer tokens, parser recovery) |
| [`libruntime/`](libruntime/) | C runtime library for print/println helpers |
| [`test/`](test/) | Test harness, test cases and golden files (see [`test/README.md`](test/README.md)) |

## Getting started

1. **Fork** this repository.
2. Read [`doc/grammar1.md`](doc/grammar1.md) — this is the first language you need to support.
3. **Install the toolchain**: see [`doc/setup.md`](doc/setup.md) for LLVM/Clang
   installation instructions.
4. Set up your compiler project in the language of your choice.
5. **Configure the test harness** to point to your compiler:
   - Copy `test/config.json` to your own config (or edit it in place).
   - Set the `build` command, `stages` commands, and `default_grammar` to match your compiler.
   - See [`test/README.md`](test/README.md) for the full config format.
6. Write a **lexer** that tokenises the grammar, outputting tokens as JSON.
7. Use the test harness to run the provided lexer tests:
   ```
   python3 test/run_tests.py --stage lexer --grammar 1
   ```
8. Once lexer passes, implement the **parser** to produce an AST in JSON format.
9. Then implement **LLVM IR code generation** so that a `.spl` source can be compiled
   and run.

For each grammar version, new test cases (positive and negative) are provided
for each stage (lexer, parser, LLVM IR, full compile-and-run).

## Test harness

The test harness lives in `test/`. Configure it to point at your own compiler
binary by editing `test/config.json` (or creating a separate config file).

```
python3 test/run_tests.py
```

See [`test/README.md`](test/README.md) for the full documentation.

## Runtime library

The `libruntime/` directory contains a small C runtime library that provides
helper functions (`print_int`, `println_int`, `println`, `print_string`,
`println_string`). Starting with grammar 3, your compiler can declare these as `extern` functions and
link with the library when producing executables.

See [`doc/runtime.md`](doc/runtime.md) for the API reference and
[`doc/setup.md`](doc/setup.md) for building and linking it.

## Gradual grammar progression

1. **Expressions** — variables, assignments, `return` statement (everything is `Int64`)
2. **Control flow** — `if`/`while`/`break`/`continue`
3. **Functions** — `def`/`extern`, calling C helpers
4. **Primitive types** — `Int8`, `Int16`, `Int32`, `Int64`, `Bool`, `String` + `cast`
5. **Structs and arrays** — typed fields, stack-allocated arrays

## CI

The repository includes a GitHub Actions workflow (`.github/workflows/tests.yml`)
that runs the test harness. You will need to edit it to build your compiler
before it can run.

## Questions?

Refer to the course materials, ask during seminars or in chat group.
