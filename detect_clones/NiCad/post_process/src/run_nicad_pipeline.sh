#!/usr/bin/env bash
set -Eeuo pipefail
shopt -s nullglob

INPUT_DIR="/home/user1-system11/research_dream/clone_research/postprocess-clone-results/java/Nicad/input"
OUTPUT_ROOT="/home/user1-system11/research_dream/clone_research/postprocess-clone-results/java/Nicad/output"
PROJECTS_ROOT="/home/user1-system11/research_dream/clone_research/clone_detectors/NiCad"

STEP1="python 1_nicad_xml_to_jsonl.py"
STEP2="python 2_java_qmethod_ts.py"

# safety checks
[[ -d "$INPUT_DIR" ]] || { echo "ERROR: INPUT_DIR not found: $INPUT_DIR" >&2; exit 1; }
[[ -d "$OUTPUT_ROOT" ]] || mkdir -p "$OUTPUT_ROOT"
[[ -e "$PROJECTS_ROOT" ]] || { echo "ERROR: PROJECTS_ROOT not found: $PROJECTS_ROOT" >&2; exit 1; }

xmls=( "$INPUT_DIR"/*withsource.xml )
if (( ${#xmls[@]} == 0 )); then
  echo "No .xml files found in: $INPUT_DIR" >&2
  exit 1
fi

echo "Found ${#xmls[@]} XML files."

for xml in "${xmls[@]}"; do
  fname="$(basename "$xml")"

  # Extract system name from filename:
  # e.g., activemq-java_functions-blind-clones-0.30-classes-withsource.xml -> activemq-java
  system="${fname%%_*}"
  if [[ "$system" == "$fname" ]]; then
    # fallback if no underscore exists
    system="${fname%%-functions*}"
    system="${system%%-classes*}"
    system="${system%%.xml}"
  fi

  outdir="$OUTPUT_ROOT/$system"
  mkdir -p "$outdir"

  step1_out="$outdir/step1_nicad_${system}_sim0.7_classes.jsonl"
  step1_log="$outdir/step1_nicad_${system}_sim0.7_classes.log"

  step2_out="$outdir/step2_nicad_${system}_sim0.7_classes_fqn.jsonl"
  step2_log="$outdir/step2_nicad_${system}_sim0.7_classes_fqn.log"

  echo "============================================================"
  echo "SYSTEM: $system"
  echo "XML:    $xml"
  echo "OUTDIR: $outdir"
  echo "------------------------------------------------------------"
  echo "[1/2] Step1 -> $step1_out"
  # run step1
  bash -lc "$STEP1 --xml \"$xml\" --out \"$step1_out\" --mode class > \"$step1_log\" 2>&1"

  echo "[2/2] Step2 -> $step2_out"
  # run step2
  bash -lc "$STEP2 --in \"$step1_out\" --out \"$step2_out\" --projects-root \"$PROJECTS_ROOT\" > \"$step2_log\" 2>&1"

  echo "DONE: $system"
done

echo "============================================================"
echo "All done. Outputs are under: $OUTPUT_ROOT/<system>/"
