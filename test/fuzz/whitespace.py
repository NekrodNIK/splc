"""Custom serializer for Grammarinator that inserts whitespace and comments.

Grammarinator's default serializer concatenates the raw text of all generated
lexer tokens, so a program generated from the reference grammar (doc/grammar1.g4)
would have no whitespace or comments at all (the .md grammar has none either).

This serializer walks the generated tree's token stream and, between every pair
of adjacent tokens, inserts an arbitrary amount of whitespace (spaces, tabs and
newlines) and, with some probability, a comment (single- or multi-line).
Lexical tokens themselves are never split, so the produced source stays valid
for a real lexer.

To use it:

    grammarinator-generate <gen> -r program -n 10 -s whitespace.whitespace_serializer ...
"""

import random


def _chars():
    return 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_ \t'


def _line_comment():
    body = ''.join(random.choice(_chars().replace('\t', '')) for _ in range(random.randint(0, 12)))
    return '//' + body + '\n'


def _block_comment():
    body = ''.join(random.choice(_chars()) for _ in range(random.randint(0, 10)))
    return '/*' + body + '*/'


def _whitespace():
    return ''.join(random.choice(' \t\n') for _ in range(random.randint(1, 3)))


def _gap():
    """Return the separator to place between two adjacent tokens.

    Always returns a non-empty separator so neighbouring lexemes never get
    concatenated into a single token (e.g. ``val`` + ``x`` must not become
    ``valx``). Either a comment or some whitespace.
    """
    if random.random() < 0.30:
        return _comment()
    return _whitespace()


def _comment():
    return _line_comment() if random.random() < 0.5 else _block_comment()


def whitespace_serializer(root) -> str:
    tokens = list(root.tokens())
    if not tokens:
        return ''
    parts = []
    for i, tok in enumerate(tokens):
        parts.append(tok)
        if i < len(tokens) - 1:
            parts.append(_gap())
    return ''.join(parts)
