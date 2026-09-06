#!/usr/bin/env python3
"""Deterministic stand-in for the compiler used by the run_tests.py self-tests.

It emulates the shape of `splc`'s command line so the harness can run it as a
"stage" without a real compiler being built. Behavior is controlled by a
directive on the first non-comment line of the source:

    // exit: N     write output then exit with code N
    // crash       kill ourselves with SIGSEGV (simulates a compiler crash)
    // sleep       block (used with a small meta timeout to test timeouts)

With no directive the mock writes a small, fixed token stream and exits 0, which
is enough to exercise golden comparison, preprocessing and update mode.

Flags: -h, -t TOKENS.json, -o OUT.ll, -a AST.json, SOURCE.spl (mirrors splc).
"""

import argparse
import json
import os
import signal
import sys
import time


def token_stream():
    return [
        {"kind": "IDENT", "value": "x", "line": 1, "column": 1},
        {"kind": "SEMICOLON", "value": ";", "line": 1, "column": 2},
    ]


def read_directive(path):
    with open(path, encoding="utf-8", errors="replace") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            return line
    return ""


def main():
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("-t", dest="tokens")
    ap.add_argument("-o", dest="out_ll")
    ap.add_argument("-a", dest="ast")
    ap.add_argument("source", nargs="?")
    args = ap.parse_args()

    if not args.source:
        print("Usage: mock_compiler [-t TOKENS.json] [-o OUT.ll] [-a AST.json] SOURCE.py",
              file=sys.stderr)
        return 3

    directive = read_directive(args.source)

    if args.tokens:
        with open(args.tokens, "w", encoding="utf-8") as f:
            json.dump(token_stream(), f, indent=2)
    if args.ast:
        with open(args.ast, "w", encoding="utf-8") as f:
            json.dump({"kind": "ast", "ok": True}, f, indent=2)

    if directive.startswith("// exit:"):
        return int(directive.split(":", 1)[1].strip())
    if directive == "// crash":
        os.kill(os.getpid(), signal.SIGSEGV)
    if directive == "// sleep":
        time.sleep(60)
    return 0


if __name__ == "__main__":
    sys.exit(main())
