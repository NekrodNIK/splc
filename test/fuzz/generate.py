#!/usr/bin/env python3
"""Generate random SysProLang test sources with Grammarinator.

Turns the reference grammar (doc/grammar1.g4, or one given with --grammar) into
a Grammarinator fuzzer and produces N random programs. Whitespace and comments
are inserted arbitrarily between terms by the serializer in this directory
(whitespace.py). Generated programs are written to the build dir
(test/build/fuzz by default) with the compiled Grammarinator fuzzer under
test/build/fuzz/grammarinator, all kept out of version control.

Generation depth is left unlimited (Grammarinator's default) so recursive
constructs such as parenthesized expressions always have enough depth budget;
--max-tokens caps the size of each generated program, which is what keeps
outputs small and varied. This is grammar-agnostic: deeper or deeper-nesting
grammars still get full coverage without producing huge files.

Usage:
    python3 test/fuzz/generate.py -n 10
    python3 test/fuzz/generate.py -n 50 --out /tmp/samples --max-tokens 30 --seed 7
"""

import argparse
import os
import re
import shutil
import subprocess
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
DEFAULT_GRAMMAR = os.path.join(REPO_ROOT, "doc", "grammar1.g4")
DEFAULT_BUILD = os.path.join(REPO_ROOT, "test", "build", "fuzz", "grammarinator")
DEFAULT_OUT = os.path.join(REPO_ROOT, "test", "build", "fuzz")
DEFAULT_MAX_TOKENS = 30
SERIALIZER_DIR = os.path.join(REPO_ROOT, "test", "fuzz")


def _find_tool(name):
    exe = shutil.which(name)
    if exe:
        return [exe]
    return [sys.executable, "-m", "grammarinator." + name.replace("grammarinator-", "")]


def _log(msg):
    print(msg, file=sys.stderr)


def _run(cmd, **kwargs):
    _log("$ " + " ".join(cmd))
    try:
        subprocess.run(cmd, check=True, **kwargs)
    except FileNotFoundError as e:
        sys.stderr.write(
            "error: '%s' not found; is Grammarinator installed? (pip install grammarinator)\n"
            % cmd[0])
        sys.exit(1)
    except subprocess.CalledProcessError as e:
        _log(f"error: {cmd[0]} failed with exit code {e.returncode}")
        sys.exit(e.returncode or 1)


def build_fuzzer(grammar, build_dir):
    """Compile the ANTLR grammar into a Grammarinator generator."""
    shutil.rmtree(build_dir, ignore_errors=True)
    os.makedirs(build_dir, exist_ok=True)
    _run([*_find_tool("grammarinator-process"), grammar, "-o", build_dir, "--no-actions"])


def generator_class(build_dir, grammar):
    """Derive the package-less module.class reference for grammarinator-generate."""
    name = os.path.splitext(os.path.basename(grammar))[0]
    cls = name + "Generator"
    return build_dir, f"{cls}.{cls}"


def generate(n, out_dir, max_depth, max_tokens, seed, verify, build_dir, serializer_ref):
    os.makedirs(out_dir, exist_ok=True)
    scratch = os.path.join(out_dir, ".scratch")
    base = [
        *_find_tool("grammarinator-generate"),
        serializer_ref,
        "-r", "program",
        "-n", str(n),
        "-o", os.path.join(scratch, "test_%d.spl"),
        "-s", "whitespace.whitespace_serializer",
        "--sys-path", build_dir,
        "--sys-path", SERIALIZER_DIR,
        "-j", "1",
        "--max-tokens", str(max_tokens),
        "--memo-size", str(max(2 * n, 10)),
    ]
    if max_depth is not None:
        base += ["--max-depth", str(max_depth)]

    # Grammarinator may legitimately produce empty programs (program ::= { statement } EOF).
    # Generate into a scratch dir, keep only non-empty outputs, and fill the out
    # directory with unique test_N names until we have the requested count.
    counter = 0
    attempts = 0
    try:
        while counter < n and attempts < 30:
            shutil.rmtree(scratch, ignore_errors=True)
            os.makedirs(scratch)
            cmd = base + (["--random-seed", str(seed + attempts)] if seed is not None else [])
            _run(cmd)
            for path in sorted(_files(scratch)):
                if os.path.getsize(path) > 0:
                    shutil.copy2(path, os.path.join(out_dir, f"test_{counter}.spl"))
                    counter += 1
                    if counter >= n:
                        break
            attempts += 1
    finally:
        shutil.rmtree(scratch, ignore_errors=True)

    if counter < n:
        _log(f"warning: only produced {counter} of {n} requested non-empty sample(s)")

    samples = sorted(_non_empty(out_dir))
    if verify:
        _verify(samples)
    return samples


def _non_empty(out_dir):
    return [p for p in sorted(_files(out_dir)) if os.path.getsize(p) > 0]


def _files(out_dir):
    if not os.path.isdir(out_dir):
        return []
    return [os.path.join(out_dir, f) for f in os.listdir(out_dir) if f.startswith("test_") and f.endswith(".spl")]


def _verify(samples):
    exe = os.path.join(REPO_ROOT, "build", "splc")
    for path in samples:
        _run([exe, "-t", os.devnull, path])


def main(argv=None):
    ap = argparse.ArgumentParser(description=__doc__,
                                 formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("-n", type=int, default=10, help="number of non-empty samples to generate (default: 10)")
    ap.add_argument("--out", default=DEFAULT_OUT, help=f"output directory (default: {DEFAULT_OUT})")
    ap.add_argument("--grammar", default=DEFAULT_GRAMMAR, help=f"grammar file (default: {DEFAULT_GRAMMAR})")
    ap.add_argument("--build", default=DEFAULT_BUILD, help=f"fuzzer build dir (default: {DEFAULT_BUILD})")
    ap.add_argument("--max-depth", "-d", type=int, default=None,
                    help="optional max generation depth; defaults to unlimited "
                         "(output size is bounded by --max-tokens instead)")
    ap.add_argument("--max-tokens", type=int, default=DEFAULT_MAX_TOKENS,
                    help=f"max tokens per generated program; this caps output size "
                         f"(default: {DEFAULT_MAX_TOKENS})")
    ap.add_argument("--seed", type=int, default=None, help="random seed")
    ap.add_argument("--verify", action="store_true", help="run the built compiler's lexer on the samples")
    ap.add_argument("--show", type=int, default=10, help="how many samples to print (default: 10)")
    ap.add_argument("--quiet", action="store_true",
                    help="do not echo generated samples to stdout (run_tests uses this)")
    args = ap.parse_args(argv)

    build_dir, serializer_ref = generator_class(args.build, args.grammar)
    build_fuzzer(args.grammar, args.build)

    if args.max_depth is not None and args.max_depth < 8:
        _log(f"warning: --max-depth {args.max_depth} is too small to fit any "
             "statement; the grammar's nesting depth requires >= 8")
    if args.max_tokens < 3:
        _log(f"warning: --max-tokens {args.max_tokens} is too small to fit even "
             "one statement")

    samples = generate(args.n, args.out, args.max_depth, args.max_tokens,
                       args.seed, args.verify, build_dir, serializer_ref)

    if not args.quiet:
        print(f"\nGenerated {len(samples)} non-empty sample(s) in {os.path.abspath(args.out)}:\n")
        for i, path in enumerate(samples[:args.show], 1):
            with open(path) as f:
                print(f"===== sample {i}: {os.path.basename(path)} =====")
                print(f.read())
    else:
        for path in samples:
            print(path)


if __name__ == "__main__":
    main()
