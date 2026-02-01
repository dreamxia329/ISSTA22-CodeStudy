#!/bin/bash

# ------------------------------------------------------------------
# [Auto-Detect] Count the number of available GPUs
# ------------------------------------------------------------------
NUM_GPUS=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)
echo "======================================================="
echo "Detected GPUs: $NUM_GPUS"
echo "======================================================="

# ------------------------------------------------------------------
# [Smart Batching] Calculate Accumulation Steps
# Goal: Maintain a Global Batch Size of ~64 regardless of GPU count.
# Formula: Global Batch = (Per GPU Batch) * (Num GPUs) * (Accumulation)
# ------------------------------------------------------------------
PER_GPU_BATCH=8
TARGET_GLOBAL_BATCH=64

# Bash integer division automatically floors the result
ACCUM_STEPS=$(( TARGET_GLOBAL_BATCH / (PER_GPU_BATCH * NUM_GPUS) ))

# Ensure accumulation is at least 1
if [ "$ACCUM_STEPS" -lt 1 ]; then
    ACCUM_STEPS=1
fi

echo "Auto-Configured Hyperparameters:"
echo " - Num Processes : $NUM_GPUS"
echo " - Per GPU Batch : $PER_GPU_BATCH"
echo " - Accumulation  : $ACCUM_STEPS"
echo " - Global Batch  : $(( PER_GPU_BATCH * NUM_GPUS * ACCUM_STEPS )) (Target: ~$TARGET_GLOBAL_BATCH)"
echo "======================================================="

# ------------------------------------------------------------------
# [Command Builder] Configure 'accelerate launch' flags
# ------------------------------------------------------------------
LAUNCH_CMD="accelerate launch"

if [ "$NUM_GPUS" -gt 1 ]; then
    # Add multi-gpu flags only if more than 1 GPU is detected
    LAUNCH_CMD="$LAUNCH_CMD --multi_gpu --num_processes $NUM_GPUS"
fi

# ------------------------------------------------------------------
# [Execution] Start Training
# ------------------------------------------------------------------
mkdir -p ./saved_models/

# Note: The 'tee' command will save logs to train_auto_detect.log
$LAUNCH_CMD run.py \
    --output_dir=./saved_models/ \
    --model_type=gpt2 \
    --config_name=microsoft/CodeGPT-small-java-adaptedGPT2 \
    --model_name_or_path=microsoft/CodeGPT-small-java-adaptedGPT2 \
    --tokenizer_name=microsoft/CodeGPT-small-java-adaptedGPT2 \
    --do_train \
    --do_test \
    --train_data_file=../dataset/train.txt \
    --eval_data_file=../dataset/valid.txt \
    --test_data_file=../dataset/test.txt \
    --block_size 1024 \
    --train_batch_size $PER_GPU_BATCH \
    --gradient_accumulation_steps $ACCUM_STEPS \
    --eval_batch_size 32 \
    --epoch 2 \
    --learning_rate 5e-5 \
    --max_grad_norm 1.0 \
    --evaluate_during_training \
    --save_steps 500 \
    --save_total_limit 2 \
    --overwrite_output_dir \
    --seed 3 2>&1 | tee ./saved_models/train_auto_detect.log