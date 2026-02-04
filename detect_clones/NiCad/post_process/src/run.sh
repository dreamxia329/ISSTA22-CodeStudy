LOG=../data/java/pipeline.log

mkdir -p ../data/java && \
echo "============================================================" | tee -a "$LOG" && \
echo "[STEP 1] 1_nicad_xml_to_jsonl.py  $(date)" | tee -a "$LOG" && \
echo "============================================================" | tee -a "$LOG" && \
python 1_nicad_xml_to_jsonl.py \
  --xml ../input/camel-java_functions-blind-clones-0.30-classes-withsource.xml \
  --out ../data/java/step1_nicad_camel_sim0.7_classes.jsonl \
  --mode class \
  2>&1 | tee -a "$LOG"

echo "------------------------------------------------------------" | tee -a "$LOG" && \
echo "[STEP 2] 2_java_qmethod_ts.py  $(date)" | tee -a "$LOG" && \
echo "------------------------------------------------------------" | tee -a "$LOG" && \
python 2_java_qmethod_ts.py \
  --in ../data/java/step1_nicad_camel_sim0.7_classes.jsonl \
  --out ../data/java/camel_sim0.7.jsonl \
  --projects-root ../.. \
  2>&1 | tee -a "$LOG"