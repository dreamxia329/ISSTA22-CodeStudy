#!/bin/bash

# ------------------------------------------------------------------
# [Auto-Detect] GPU 감지 및 설정
# ------------------------------------------------------------------
NUM_GPUS=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
PER_GPU_BATCH=8
TARGET_GLOBAL_BATCH=64
ACCUM_STEPS=$(( TARGET_GLOBAL_BATCH / (PER_GPU_BATCH * NUM_GPUS) ))
[ "$ACCUM_STEPS" -lt 1 ] && ACCUM_STEPS=1

echo "=== Debugging Mode (Small Data) ==="
echo "GPUs: $NUM_GPUS | Accumulation: $ACCUM_STEPS"

LAUNCH_CMD="accelerate launch"
[ "$NUM_GPUS" -gt 1 ] && LAUNCH_CMD="$LAUNCH_CMD --multi_gpu --num_processes $NUM_GPUS"

# ------------------------------------------------------------------
# [Execution] 작은 데이터셋 & 자주 저장 (Step=5)
# ------------------------------------------------------------------
mkdir -p ./saved_models_debug/

$LAUNCH_CMD run.py \
    --output_dir=./saved_models_debug/ \
    --model_type=gpt2 \
    --config_name=microsoft/CodeGPT-small-java-adaptedGPT2 \
    --model_name_or_path=microsoft/CodeGPT-small-java-adaptedGPT2 \
    --tokenizer_name=microsoft/CodeGPT-small-java-adaptedGPT2 \
    --do_train \
    --do_test \
    --evaluate_during_training \
    --train_data_file=../dataset/train_small.txt \
    --eval_data_file=../dataset/valid_small.txt \
    --test_data_file=../dataset/test_small.txt \
    --block_size 1024 \
    --train_batch_size $PER_GPU_BATCH \
    --gradient_accumulation_steps $ACCUM_STEPS \
    --eval_batch_size 32 \
    --epoch 1 \
    --learning_rate 5e-5 \
    --max_grad_norm 1.0 \
    --evaluate_during_training \
    --save_steps 5 \
    --logging_steps 5 \
    --save_total_limit 2 \
    --overwrite_output_dir \
    --seed 3 2>&1 | tee ./saved_models_debug/debug.log