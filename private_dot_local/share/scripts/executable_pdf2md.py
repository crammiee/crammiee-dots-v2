#!/usr/bin/env -S uv run --script
# desc: convert a PDF to Markdown on stdout
# /// script
# dependencies = ["pymupdf4llm"]
# ///
import sys
import pymupdf4llm

if len(sys.argv) != 2:
    print("usage: s pdf2md <file.pdf>", file=sys.stderr)
    sys.exit(1)

print(pymupdf4llm.to_markdown(sys.argv[1]))
