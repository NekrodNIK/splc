# SysProLang

Version: 1

## Grammar

```bnf
program ::= { statement } EOF

statement ::=
    returnStatement
  | declarationStatement
  | assignmentStatement
  | expressionStatement

returnStatement ::= "return" expression ";"

declarationStatement ::= "val" IDENT "=" expression ";"
                       | "var" IDENT "=" expression ";"

assignmentStatement ::= IDENT "=" expression ";"

expressionStatement ::= expression ";"

; Expression definitions go from lowest operator precedence
; to the highest, allowing for straightforward expression parsing.
expression ::= additiveExpression

additiveExpression ::=
    multiplicativeExpression { ("+" | "-") multiplicativeExpression }

multiplicativeExpression ::=
    unaryExpression { ("*" | "/") unaryExpression }

unaryExpression ::=
    "-" unaryExpression
  | primaryExpression

primaryExpression ::=
    INTEGER_LITERAL
  | IDENT
  | "(" expression ")"


; Lexical tokens

INTEGER_LITERAL ::=
    "0"
  | NON_ZERO_DIGIT { DIGIT }

IDENT ::= NON_DIGIT { (NON_DIGIT | DIGIT) }

NON_DIGIT ::=
    "a" | "b" | ... | "z"
  | "A" | "B" | ... | "Z"
  | "_"

DIGIT ::= "0" | NON_ZERO_DIGIT

NON_ZERO_DIGIT ::=
    "1" | "2" | ... | "9"
```

> Comments and whitespaces are not explicit in above grammar.
> It is assumed that all terms in grammar rules (except lexical tokens)
> can have arbitrary number of whitespaces and/or comments between them.

### Comments

SysProLang uses C-style comments:

- Single-line: `//` ... end-of-line
- Multi-line: `/*` ... `*/`

### Keywords

- `return`
- `val`
- `var`

### Semantic rules

- **All variables must be declared** with `var` or `val` before use. Assignment to an
  undeclared identifier is a semantic error.
- **`val` declarations are immutable**: a `val` variable cannot appear on the left-hand
  side of an assignment.
- **Every program must have at least one statement** before EOF. The last statement must
  be a `return` statement (which terminates the implicit `main()` function).
- **All values are `Int64`** (64-bit signed integer). Integer literals are implicitly
  `Int64`.
- **The program body is the implicit `main()` function**: it is compiled as if wrapped
  in `def main() -> Int64 { ... }`. The `return` statement provides the return value.
- **Operator precedence** is encoded in the grammar: `+`/`-` lower than `*`/`/`,
  unary `-` highest. Parentheses override precedence.
- **Comments and whitespace** are ignored by the parser (handled by the lexer).
- **Error recovery**: see [`doc/error-handling.md`](error-handling.md) for the
  recommended error recovery strategy.
