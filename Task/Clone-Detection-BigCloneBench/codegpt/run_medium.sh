#!/bin/bash

# ==================================================================
# 1. Data Preparation (Medium Size: 20k)
# ==================================================================
echo ">>> [Step 1] Generating Medium Dataset (20k lines)..."

# Create medium-sized datasets (approx. 20% of full data)
# Use head to extract the first N lines
head -n 20000 ../dataset/train.txt > ../dataset/train_medium.txt
head -n 2000 ../dataset/valid.txt > ../dataset/valid_medium.txt
head -n 2000 ../dataset/test.txt > ../dataset/test_medium.txt

echo "    - Train: $(wc -l < ../dataset/train_medium.txt) lines"
echo "    - Valid: $(wc -l < ../dataset/valid_medium.txt) lines"
echo "    - Test : $(wc -l < ../dataset/test_medium.txt) lines"


# ==================================================================
# 2. Safety Patch (Fixing run.py Logic)
# ==================================================================
echo ">>> [Step 2] Applying Safety Patches to run.py..."

# Patch A: Disable the logic that overrides user's --save_steps
# The original code forces save_steps = len(dataloader), we comment it out.
sed -i "s/args.save_steps=len( train_dataloader)/# args.save_steps=len( train_dataloader)/g" run.py
sed -i "s/args.logging_steps=len( train_dataloader)/# args.logging_steps=len( train_dataloader)/g" run.py

# Patch B: Ensure first checkpoint saves even if F1 score is 0.0
# Change initialization of best_f1 from 0 to -1
sed -i "s/best_f1=0/best_f1=-1/g" run.py

echo "    - Patched: run.py now respects --save_steps argument."
echo "    - Patched: run.py will save the first model even if F1 is 0."


# ==================================================================
# 3. Hardware Auto-Detection & Scaling
# ==================================================================
echo ">>> [Step 3] Configuring Hardware..."

# Count available GPUs
NUM_GPUS=$(nvidia-smi --query-gpu=name --format=csv,noheader | wc -l)

# Set Batch Parameters
PER_GPU_BATCH=8
TARGET_GLOBAL_BATCH=64

# Calculate Gradient Accumulation Steps
# Formula: Accumulation = 64 / (8 * Num_GPUs)
ACCUM_STEPS=$(( TARGET_GLOBAL_BATCH / (PER_GPU_BATCH * NUM_GPUS) ))

# Safety check: Accumulation must be at least 1
[ "$ACCUM_STEPS" -lt 1 ] && ACCUM_STEPS=1

echo "    - GPUs detected: $NUM_GPUS"
echo "    - Accumulation : $ACCUM_STEPS"
echo "    - Effective Batch Size: $(( PER_GPU_BATCH * NUM_GPUS * ACCUM_STEPS ))"


# ==================================================================
# 4. Execution
# ==================================================================
# Build the launch command based on GPU count
LAUNCH_CMD="accelerate launch"
[ "$NUM_GPUS" -gt 1 ] && LAUNCH_CMD="$LAUNCH_CMD --multi_gpu --num_processes $NUM_GPUS"

# Create output directory
mkdir -p ./saved_models_medium/

echo ">>> [Step 4] Starting Training..."
echo "    - Save Frequency: Every 200 steps"
echo "    - Log File: ./saved_models_medium/medium.log"

$LAUNCH_CMD run.py \
    --output_dir=./saved_models_medium/ \
    --model_type=gpt2 \
    --config_name=microsoft/CodeGPT-small-java-adaptedGPT2 \
    --model_name_or_path=microsoft/CodeGPT-small-java-adaptedGPT2 \
    --tokenizer_name=microsoft/CodeGPT-small-java-adaptedGPT2 \
    --do_train \
    --do_test \
    --train_data_file=../dataset/train_medium.txt \
    --eval_data_file=../dataset/valid_medium.txt \
    --test_data_file=../dataset/test_medium.txt \
    --block_size 1024 \
    --train_batch_size $PER_GPU_BATCH \
    --gradient_accumulation_steps $ACCUM_STEPS \
    --eval_batch_size 32 \
    --epoch 2 \
    --learning_rate 5e-5 \
    --max_grad_norm 1.0 \
    --evaluate_during_training \
    --save_steps 200 \
    --logging_steps 50 \
    --save_total_limit 2 \
    --overwrite_output_dir \
    --seed 3 2>&1 | tee ./saved_models_medium/medium.log