--

# Installation Guide: Clone Detection Research Environment

This repository contains the environment setup and benchmarking tools for evaluating Pre-trained Models (PTMs) on the **BigCloneBench** dataset. This setup is optimized for high-performance deep learning on dual NVIDIA RTX 6000 Ada GPUs.

## 1. System Requirements

* **OS:** Ubuntu 22.04+ (or compatible Linux distribution)
* **Hardware:** 2x NVIDIA RTX 6000 Ada (96GB total VRAM)
* **Driver:** NVIDIA Driver version 550.142+
* **CUDA:** 12.4
* **Language:** Python 3.11

## 2. Environment Setup

We recommend using **Miniconda** to manage the research environment. This ensures that CUDA-specific libraries are correctly linked without interfering with system-level packages.

### Step 1: Create the Conda Environment

```bash
conda create -n bigclone python=3.11 -y
conda activate bigclone

```

### Step 2: Install PyTorch with CUDA 12.4 Support

Install the core deep learning framework directly via the `pytorch` and `nvidia` channels. This ensures that the internal `nvcc` tools and shared libraries are perfectly matched to your hardware.

```bash
conda install pytorch torchvision torchaudio pytorch-cuda=12.4 -c pytorch -c nvidia -y

```

### Step 3: Resolve Intel MKL Library Conflicts (Critical)

**Note:** A known conflict exists between the latest Intel Math Kernel Library (MKL) 2025.x provided by the default Conda channel and the PyTorch binaries, which often expect MKL 2024.x. This mismatch causes an `undefined symbol: iJIT_NotifyEvent` error when importing torch.

To prevent this, explicitly downgrade the MKL library to the compatible 2024 version:

```bash
conda install "mkl<2025" -y

```

### Step 4: Install Research Dependencies

Use the provided `requirements.txt` to install the Transformers library, database connectors for BigCloneBench, and structural parsing tools.

**Important:** Ensure your `requirements.txt` **does not** contain `torch`, `torchvision`, or `torchaudio`, as installing these via pip will overwrite the optimized Conda binaries and re-introduce library conflicts.

```bash
pip install -r requirements.txt

```

## 3. Verifying the Setup

Run the following Python snippet to verify that both RTX 6000 GPUs are visible, the MKL libraries are linking correctly, and the environment can perform parallel operations:

```python
import torch

print(f"CUDA Available: {torch.cuda.is_available()}")
print(f"GPU Count: {torch.cuda.device_count()}")

for i in range(torch.cuda.device_count()):
    print(f"GPU {i}: {torch.cuda.get_device_name(i)}")
    # Test tensor allocation on each GPU
    x = torch.rand(1000, 1000).to(f'cuda:{i}')
    print(f"Successfully allocated tensor on GPU {i}")

```

---

## 4. Scientific and Outreach Context

This setup is a core part of our ongoing research into **AI-Driven Software Intelligence and Collaboration**. A primary goal of this repository is the **mentorship of undergraduate and graduate researchers** through the full lifecycle of high-impact projects.

* **Research Focus:** We leverage Large Language Models (LLMs) and datasets like BigCloneBench to automate complex software engineering tasks such as code summarization and clone detection.
* **Mentorship:** Students contribute to this project by managing the AI infrastructure, configuring CUDA-accelerated environments, and conducting large-scale benchmarking. This includes gaining hands-on experience in resolving complex system-level dependencies, such as the Intel MKL binary conflicts documented above.
* **Preparation:** By guiding students from initial environment design to the deployment of models like **SYNCode**, we are preparing the next generation of engineers for a future where AI and human expertise work in tandem.
