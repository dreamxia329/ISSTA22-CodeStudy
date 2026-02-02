#!/usr/bin/env python3
import argparse
import json
import os
import re
import sys
from typing import Dict, Any, List

# ---- Default Paths ----
DEFAULT_INPUT = "data/step2_nicad_camel-java_sim0.7_classes_fqn.jsonl"
DEFAULT_OUTPUT = "data/nicad_camel_clone_func.jsonl"

# ---- Test detection rules ----
TEST_DIR_PATTERNS = [
    r"(^|/)src/test(/|/java/|/resources/|$)",
    r"(^|/)src/it(/|$)",
    r"(^|/)src/integration-test(/|$)",
    r"(^|/)test(/|$)",
    r"(^|/)tests(/|$)",
]

TEST_FILENAME_PATTERNS = [
    r"Test\.java$",
    r"Tests\.java$",
    r"TestCase\.java$",
    r"IT\.java$",
    r"ITCase\.java$",
    r"IntegrationTest\.java$",
]

TEST_DIR_RES = [re.compile(p) for p in TEST_DIR_PATTERNS]
TEST_FILE_RES = [re.compile(p) for p in TEST_FILENAME_PATTERNS]


def is_test_path(path: str) -> bool:
    """Check if the file path matches any test directory or filename patterns."""
    norm = path.replace("\\", "/")
    for r in TEST_DIR_RES:
        if r.search(norm):
            return True
    base = os.path.basename(norm)
    for r in TEST_FILE_RES:
        if r.search(base):
            return True
    return False


def group_has_any_test_source(obj: Dict[str, Any]) -> bool:
    """Return True if any source within the group is identified as a test file."""
    for s in obj.get("sources", []):
        if is_test_path(s.get("file", "")):
            return True
    return False


def main():
    ap = argparse.ArgumentParser(
        description="Filter out test functions and limit clone group size from a NiCad clone JSONL file."
    )
    # Set default values to allow execution without explicit command line arguments
    ap.add_argument("--input", default=DEFAULT_INPUT, help=f"Input JSONL file (default: {DEFAULT_INPUT})")
    ap.add_argument("--output", default=DEFAULT_OUTPUT, help=f"Output JSONL file (default: {DEFAULT_OUTPUT})")
    ap.add_argument(
        "--mode",
        choices=["drop_group_if_any_test", "drop_only_test_sources"],
        default="drop_group_if_any_test",
        help="Filtering mode for test files."
    )
    # Max clones limit based on Professor's directive: nclones < 20
    ap.add_argument(
        "--max_clones",
        type=int,
        default=20,
        help="Discard groups where nclones is equal to or greater than this value (default: 20)."
    )
    args = ap.parse_args()

    in_path = args.input
    out_path = args.output

    kept_groups = 0
    dropped_groups_test = 0
    dropped_groups_size = 0
    total_groups = 0

    if not os.path.exists(os.path.dirname(out_path)) and os.path.dirname(out_path) != "":
        os.makedirs(os.path.dirname(out_path), exist_ok=True)

    with open(in_path, "r", encoding="utf-8") as fin, open(out_path, "w", encoding="utf-8") as fout:
        for line_no, line in enumerate(fin, 1):
            line = line.strip()
            if not line:
                continue
            total_groups += 1
            try:
                obj = json.loads(line)
            except Exception as e:
                print(f"[ERROR] JSON parse failed at line {line_no}: {e}", file=sys.stderr)
                continue

            # ---- SIZE FILTERING LOGIC ----
            # Objective: Include only groups where nclones < 20.
            # Decision: If nclones is 20 or more, the group is discarded to prevent overfitting.
            current_nclones = obj.get("nclones", 0)
            if current_nclones >= args.max_clones:
                dropped_groups_size += 1
                continue

            # ---- TEST FILTERING LOGIC ----
            if args.mode == "drop_group_if_any_test":
                if group_has_any_test_source(obj):
                    dropped_groups_test += 1
                    continue
                fout.write(json.dumps(obj, ensure_ascii=False) + "\n")
                kept_groups += 1
            # (Note: Additional modes like 'drop_only_test_sources' can be added here if needed)

    print("--- Processing Complete ---")
    print(f"  Input groups:           {total_groups}")
    print(f"  Dropped (Size >= {args.max_clones}): {dropped_groups_size}")
    print(f"  Dropped (Test related): {dropped_groups_test}")
    print(f"  Kept groups:            {kept_groups}")
    print(f"  Output written:         {out_path}")

if __name__ == "__main__":
    main()