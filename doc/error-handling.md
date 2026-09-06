# Error Handling Strategy

This document describes the recommended error handling strategy for the compiler.
The strategy is designed to be simple to implement while still providing useful
diagnostics.

## General principles

1. **The compiler should never crash** on invalid input. All errors should be caught
   and reported gracefully.
2. **Error messages are implementation-defined.** Each compiler may format them
   differently. The test harness only checks exit codes and golden file comparisons,
   not error message text (unless the test explicitly includes `stderr` goldens).
3. **Error recovery is best-effort.** After reporting an error, the compiler attempts
   to continue and find more errors. This gives students more feedback per run.
4. **Recovery is not always possible.** Some errors cascade — a parse error may cause
   a cascade of spurious semantic errors. This is acceptable.

## Lexer errors

### Invalid characters

When an invalid character (not part of any token) is encountered, the lexer should
**emit an error token** and continue scanning after the invalid character.

```python
# Recommended approach
def next_token(reader):
    skip_whitespace_and_comments(reader)
    c = reader.peek()
    if c == '\0':
        return Token("EOF", ...)
    if c.isalpha() or c == '_':
        return scan_identifier_or_keyword(reader)
    if c.isdigit():
        return scan_integer(reader)
    if c in '+-*/();=':
        return scan_single_char(reader)
    # Invalid character — emit error token, don't skip silently
    t = Token("ERROR", "invalid character", reader.line, reader.col, ...)
    reader.advance()
    return t
```

The error token type is `ERROR` (or similar). It is a real token in the stream,
so the parser can detect it and enter recovery if needed.

### Unterminated comments

When a `/*` comment is not closed before EOF, the lexer should report an error
and continue (the comment is treated as ending at EOF). The lexer may emit an
`ERROR` token or let the parser handle the missing `*/`.

### Unterminated strings (grammar 4+)

When a string literal is not closed before end of line or EOF, the lexer should
report an error and emit an `ERROR` token.

## Parser errors

### Panic mode recovery

The recommended parser recovery strategy is **panic mode**:

1. When a parse error is detected (unexpected token), report the error.
2. Discard tokens until a **synchronization token** is found.
3. Resume parsing from after the synchronization token.

Synchronization tokens, in order of priority:
- `;` (semicolon) — ends a statement
- `}` (closing brace) — ends a block
- `EOF` — end of file

```python
# Recommended approach
def synchronize(tokens):
    """Skip tokens until a synchronization point is found."""
    while tokens.peek().type not in ("SEMI", "RBRACE", "EOF"):
        tokens.advance()
    # Consume the semicolon if we stopped at one
    if tokens.peek().type == "SEMI":
        tokens.advance()
```

### When to recover

Recovery should be attempted after:
- A statement fails to parse (skip to `;` or `}`)
- A declaration fails to parse (skip to `;` or `}`)
- An expression fails to parse (skip to `;` or `}` or `)`)

Recovery should **not** be attempted when:
- A function body fails to parse — skip to `}` and continue to the next function
- A struct definition fails to parse — skip to `}` and continue

### Error propagation

After recovery, the parser creates **sentinel nodes** (e.g., `null` or an
`ErrorStatement` node) so that the AST remains structurally valid. This prevents
the codegen stage from crashing on missing nodes.

```python
# Example: after recovery, return a sentinel
def parse_statement(tokens):
    if tokens.peek().type == "RETURN":
        return parse_return_statement(tokens)
    # ...
    else:
        error("expected statement")
        synchronize(tokens)
        return ErrorStatement()  # sentinel node
```

## Codegen errors

### Undefined variables

When a variable is referenced but not declared, the codegen should report an error
and emit a dummy value (e.g., `0`) to allow compilation to continue.

### Type errors (grammar 4+)

When a type mismatch is detected, report an error and emit a dummy value
to allow codegen to continue.

## Error messages

### Format

Error messages should include the location (line and column) and a description.
The exact format is implementation-defined. Example formats:

```
Error: line 5, column 12: undefined variable 'x'
src/grammar1/test.spl:5:12: error: expected ';' after expression
```

### What the test harness checks

The test harness compares:
- Exit codes: a non-zero exit indicates an error was detected
- Golden files: `tokens.json`, `ast.json`, `out.ll` (only with `--check-ir`),
  `stdout` are compared after preprocessing
- Error messages are **not compared** unless the test case includes a `stderr`
  golden file (which is optional)

Your compiler's internal architecture, error message wording, and recovery
heuristics may differ from other implementations as long as it produces the
correct outputs for valid programs and exits with non-zero for invalid programs.

## Testing error recovery

### Negative tests

Negative test cases in `test/grammarN/` use `"exit": "nonzero"` in `meta.json`
to indicate that the compiler should report an error. The exact error message
and recovery behavior are not checked — only that the compiler exits with a
non-zero status.

### Recovery tests

A test case that exercises error recovery should have:
- An `exit` code of `0` (the compiler recovers and produces valid output)
- A `stdout` golden file showing the output despite the error
- The error message may appear on stderr, which is not compared

## IR comparison

LLVM IR golden comparison (`out.ll` files) is **opt-in** with the `--check-ir`
flag. By default, only the `lexer`, `parser`, and `compiler` (compile + run)
stages are checked. This means your IR does not need to match any particular
formatting, register naming, or block ordering — only the produced executable
needs to produce the correct output.

Use `--check-ir` when you want to debug your IR generation by comparing it
against the expected IR structure.
