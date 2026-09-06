# Test harness

> **Note**: this starter repository ships with a `test/config.json` configured
> for an example compiler CLI (`{root}/build/splc` with `-g/-t/-a/-o` flags).
> **You must edit it** (or create your own and pass `--config`) to point at
> your own compiler build. See the [Driver config](#driver-config-configjson)
> section below for the format.

Everything is driven by a single Python script, `run_tests.py`:

```
python3 run_tests.py            # build + run all tests (lexer, parser, compile+run)
python3 run_tests.py --check-ir # build + run all tests including LLVM IR golden comparison
python3 run_tests.py build      # build only
python3 run_tests.py list       # show selected tests without running
python3 run_tests.py update     # regenerate expected files from actual output
```

> LLVM IR golden comparison (`out.ll`) is opt-in with `--check-ir`.
> By default, only lexer, parser, and compile+run stages are checked.
> This lets students use IR goldens for debugging without being blocked
> by non-deterministic IR formatting differences.

Run it from the repository root (`python3 test/run_tests.py`) or from this
directory (`python3 run_tests.py`).

## Command-line options

The first argument selects a subcommand:

| subcommand  | effect                                                        |
| ----------- | ------------------------------------------------------------- |
| `test`      | build the compiler (unless `--no-build`), then run tests. Default. |
| `build`     | run the `build` command from the config and stop.             |
| `update`    | build, then regenerate expected files from actual output.     |
| `list`      | print the tests that would run, without running anything.     |
| `list-matrix` | print a compatibility matrix showing which grammar versions each test case applies to (based on meta.json constraints). |

The following flags apply to any subcommand:

| flag                          | meaning                                                              | example                                  |
| ----------------------------- | -------------------------------------------------------------------- | ---------------------------------------- |
| `--config PATH`               | driver config to use (default: `test/config.json`)                   | `--config my_compiler.json`              |
| `--check-ir`                   | also compare LLVM IR against golden `out.ll` files (opt-in)          | `--check-ir`                             |
| `--grammar VERSION`           | run only tests applicable to this grammar version                    | `--grammar 2`                            |
| `--stage NAME`                | run only tests for this stage                                        | `--stage lexer`                          |
| `--test PATTERN`              | run only tests whose `stage/name` contains `PATTERN`                 | `--test errors`                          |
| `-v`, `--verbose`             | always print the executed command and per-test details               | `-v`                                     |
| `-j N`                        | run up to N tests in parallel                                        | `-j 4`                                   |
| `-x`, `--stop-on-fail`        | stop after the first failing test                                    | `-x`                                     |
| `--keep MODE`                 | keep workdirs for `failed` (default), `all`, or `none` of the tests  | `--keep all`                             |
| `--no-build`                  | skip the build step (used by `test`/`update`)                        | `--no-build`                             |

Selectors combine: `--stage lexer --grammar 2` runs only the lexer tests
applicable to grammar version 2. Run `python3 run_tests.py --help` for the
full list.

Intermediate files (raw stage output, preprocessed expected/actual copies) are
written under `test/build/` (configurable via `out_dir`, see below).
The directory is recreated fresh on each run;
afterwards the per-test directories are kept for failed tests only by default.
`--keep all` keeps everything, `--keep none` removes it all.

### Fuzz testing

In addition to committed tests, `--fuzz` generates random inputs with
Grammarinator and runs them through the configured stages as **exit-contract**
tests (they have no golden files): a fuzz test passes if the stage exits with
the expected code for that stage (default `0`) and fails otherwise (or on
timeout). Because grammar-driven generation yields structurally valid
programs, the expected exit is usually `0` for lexer/parser/codegen.

```
python3 run_tests.py test --fuzz --grammar 1            # config defaults
python3 run_tests.py test --fuzz --grammar 1 --fuzz-count 50 --fuzz-seed 7 -j 4
python3 run_tests.py list --fuzz --grammar 1            # show fuzz tests too
```

- `--fuzz-count N`, `--fuzz-tokens T`, `--fuzz-depth D`, `--fuzz-seed S`
  override the `fuzz` section of `config.json` (`count`, `max_tokens`
  `max_depth`, plus `seed` here).
- Generation depth is left unlimited by default so recursive constructs
  (e.g. parenthesized expressions) always have enough depth budget; output size
  is instead bounded by `fuzz.max_tokens`. This keeps programs small and varied
  without grammar-specific tuning; deeper or deeper-nesting grammars still get
  full coverage. `--fuzz-depth`/`max_depth` is an optional escape hatch.
  `generate.py` warns if too few tokens are requested to fit any statement.
- Fuzz inputs are generated into the ephemeral `out_dir` and discarded after
  the run, so `--fuzz` cannot be combined with `update`.
- Grammar version → grammar file is resolved through `fuzz.grammar` in
  `config.json`, falling back to `doc/grammarN.g4`. Students point a version at
  their own expanded grammar by editing that map (or copying it to
  `doc/grammarN.g4`).
- The Grammarinator fuzzer lives in `test/fuzz/` (`generate.py`,
  `whitespace.py`); run_tests only invokes it.

## Test layout

```
test/
  run_tests.py                    the harness
  config.json                     driver config
  grammar1/
    <test-description>/
      meta.json                   test metadata (required for discovery)
      test.spl                    source file
      tokens.json                 golden token stream     (lexer stage)
      ast.json                    golden AST              (parser stage)
      out.ll / out.bc             golden LLVM IR          (llvm stage)
      stdout                      golden program output   (compiler stage)
      stdin                       input for the program   (compiler stage)
  grammar2/
    ...
  grammar3/
    ...
```

- Each test case is a directory at any depth under `test/`, detected by the
  presence of a `meta.json` file (this is why even tests without metadata must
  have an empty `meta.json`: `{}`).
- The source file is always named `test.spl`.
- Golden files are named by stage (`tokens.json`, `ast.json`, `out.ll`,
  `stdout`) and live in the same directory as the test case.
- A test case can serve multiple stages by simply having the corresponding
  golden files, eliminating duplication across stage test directories.
- `meta.json` fields:
  - `grammar` version(s) the test applies to. Can be:
    - A flat value: `"2"`, `">=2"`, `["2", "3"]` — applies to all stages.
    - A dict mapping stage names: `{"lexer": ">=2", "parser": ">=2"}` —
      per-stage grammar constraints. A stage is skipped if its constraint
      doesn't match the target grammar.
    Absent means "any version". Run the harness with `--grammar 2` to
    select tests applicable to grammar version 2.
  - `exit` expected exit code (of the stage or program). Can be:
    - A flat value: `0` (default), `"nonzero"`, or an exact integer.
    - A dict mapping stage names: `{"lexer": 0, "parser": "nonzero"}` —
      per-stage exit expectations. Useful when a test case should pass
      lexer but fail parser (e.g., assignment to undeclared variable).
  - `timeout` time limit in seconds.
  - `stages` list of stages to run for exit-only tests that have no golden
    files (optional). Without golden files and without `stages`, the test
    is not discovered unless `exit` is `"nonzero"` or a non-zero integer
    (in which case it runs for all configured stages).

### Error messages and negative tests

- **Error messages are implementation-defined.** The test harness does not compare
  error message text (stderr output) unless the test case includes a `stderr` golden
  file.
- **Negative tests** (with `"exit": "nonzero"` or a non-zero integer) only check
  that the compiler exits with a non-zero status. The exact error message, error
  recovery behavior, and error format are not checked.
- **Error recovery strategy** is described in [`doc/error-handling.md`](../doc/error-handling.md).
  The recommended approach is panic mode for the parser (skip to `;` or `}`) and
  error tokens for the lexer (emit an error token for invalid characters).

## Driver config (`config.json`)

How each stage is invoked is entirely configurable. Stages not listed simply
skip tests for that directory. Example:

```jsonc
{
  "build": "cmake -S {root} -B {root}/build && cmake --build {root}/build",
  "out_dir": "{root}/test/build",
  "stages": {
    "lexer": {
      "cmd": ["{root}/build/splc", "--emit-tokens", "{input}"],
      "out": "{tokens_out}",
      "preprocess": [{"type": "json", "keep": ["kind", "line", "column"]}]
    }
  },
  "llvm_dis": "llvm-dis"
}
```

Placeholders are substituted in `build`, `cmd`, `out` and `out_dir` strings.

| placeholder     | meaning                                                        |
| --------------- | -------------------------------------------------------------- |
| `{root}`        | absolute path of the repository root                           |
| `{input}`       | absolute path of the test source file (`test.spl`)             |
| `{exe}`         | path of the compiled program: write here in `compile`, then `run` it |
| `{grammar}`     | target grammar version from `--grammar` CLI flag or config `default_grammar` |
| `{tokens_out}`  | file the lexer stage should write its token JSON to            |
| `{tokens_in}`   | file the token JSON can be read from (the lexer's output)      |
| `{ast_out}`     | file the parser stage should write its AST JSON to             |
| `{ast_in}`      | file the AST JSON can be read from (the parser's output)       |
| `{llvm_out}`    | file the codegen stage should write its LLVM IR to             |

> This supports both a single compiler program (e.g. using `--emit-*` flags)
> and separate stage programs that pass intermediate representations
> between stages (write to the `*_out` paths and read the `*_in` paths).
> `{tokens_in}`/`{tokens_out}` (and `{ast_in}`/`{ast_out}`) point
> to the same files; the name just reflects read vs. write intent.

> `default_grammar` sets the grammar version used when `--grammar` is not passed
> on the command line. It is strongly recommended: without either `default_grammar`
> or `--grammar` the harness refuses to run.
>
> `{grammar}` is populated from the resolved grammar version (CLI `--grammar`
> takes priority, then `default_grammar`). This allows stage commands to pass
> `-g {grammar}` to a compiler that is grammar-version-aware.
>
`preprocess` is a pipeline applied to both expected and actual files before a plain
text diff, so representations can be canonicalized without changing expected
files. Step types:

- `{"type": "json", "keep": [...]}` or `"drop": [...]` recursive field
  selection. Container subtrees are always preserved (only scalar fields are
  filtered), so whole branches cannot be pruned this way; use an `exec` step
  for that.
- `{"type": "llvm"}` canonical rename of unnamed SSA values `%N`, block
  labels `N:` and attribute groups `#N`.
- `{"type": "regex", "pattern": ..., "repl": ...}` text replacement.
- `{"type": "exec", "cmd": ["python3", "normalize.py", "{input}", "{output}"]}`
  arbitrary command, the escape hatch for bespoke canonicalization.

To use your own compiler, copy `config.json` and run
`python3 test/run_tests.py --config path/to/your/config.json`.

## Adding tests

1. Create a new directory under `test/` (e.g. `test/grammar2/custom-feature/`).
2. Write the source file as `test.spl`.
3. Create `meta.json` with at least `{}`. Add `"grammar"`, `"exit"`, etc. as
   needed.
4. For each stage your test should exercise, create the corresponding golden
   file (`tokens.json` for lexer, `ast.json` for parser, etc.).
5. Run `python3 test/run_tests.py update` to regenerate golden files from
   actual output, then review and commit the results.

## Updating expected files

`update` regenerates expected files from the actual output of compiler
configured in `config.json`. Review and commit the
results. It is fine to keep raw output since the `preprocess` pipeline
will be applied to both expected and actual files before comparison.

## Compatibility matrix

### Using the test harness (`list-matrix`)

The `list-matrix` subcommand shows which grammar versions each test case claims
to support, based on the constraints in `meta.json`. This is a static view
based on the metadata — it does not run the compiler.

```
python3 run_tests.py list-matrix
```

Output example:

```
Test case                                           G1  G2  G3  G4  G5
----------------------------------------------------------------------
grammar1/assignment-and-division                     ✓   ✓   ✓   ✓   ✓
grammar1/chained-declarations                        ✓   ✓   ✓   —   —
grammar2/dangling-else                               —   ✓   ✓   —   —
grammar4/all-types                                   —   —   —   ✓   ✓
grammar5/simple-struct                               —   —   —   —   ✓
```

Legend: `✓` = supported, `✗` = not supported, `—` = excluded by constraint.

You can filter by test name or stage:

```
python3 run_tests.py list-matrix --test dangling
python3 run_tests.py list-matrix --stage lexer
```

### Using the reference compiler (`check-compat.py`)

The `test/check-compat.py` script runs the actual compiler against each test case
and verifies exit codes, producing a compatibility matrix that shows what *really*
works. This is useful for validating that the `meta.json` constraints are correct.

```
python3 test/check-compat.py                              # test all stages
python3 test/check-compat.py --compiler path/to/my/splc   # custom compiler
python3 test/check-compat.py --stage llvm                  # only LLVM IR stage
python3 test/check-compat.py --stage lexer -v              # verbose: show errors
python3 test/check-compat.py --grammar 3                   # only grammar 3
python3 test/check-compat.py --test dangling               # filter by test name
```

The script tests three stages: `lexer`, `parser`, `llvm`. For each combination
of test case, grammar version, and stage, it runs the compiler and checks the
exit code against the expected exit contract from `meta.json`.

## Self-tests

`run_tests.py` itself is tested by a mock-compiler suite in `test/.self-test/`
(no real compiler needed). It exercises discovery, grammar-version filtering,
exit contracts, golden diffing, preprocessing, `update`/`list`, parallel
ordering, `-x`, `--keep`, error handling and `--fuzz` orchestration:

```
python3 -m pytest test/.self-test -v
```

CI (`.github/workflows/ci.yml`) runs this on every push/PR. The dot-prefixed
directory is ignored by `run_tests.py`'s own test discovery.