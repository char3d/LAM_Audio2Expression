#!/usr/bin/env bash
set -euo pipefail

# One-click setup & run script for macOS (CPU/MPS)
# - Ensures Python 3.10 via Homebrew or local Miniconda fallback
# - Creates venv/conda env, installs deps
# - Downloads assets/weights if missing
# - Launches Gradio app

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$PROJECT_ROOT"

log() { echo "[run_mac] $*"; }
warn() { echo "[run_mac][WARN] $*"; }
err() { echo "[run_mac][ERROR] $*"; }

PYTHON_BIN="$(command -v python3.10 || true)"
USE_CONDA=0

if [[ -z "${PYTHON_BIN}" ]]; then
  if command -v brew >/dev/null 2>&1; then
    log "python3.10 not found. Installing via Homebrew ..."
    brew install python@3.10 || brew upgrade python@3.10 || true
    BREW_PREFIX="$(brew --prefix)"
    PYTHON_BIN="${BREW_PREFIX}/bin/python3.10"
    if [[ ! -x "${PYTHON_BIN}" ]]; then
      warn "Homebrew install didn't yield python3.10; will fallback to Miniconda."
      USE_CONDA=1
    fi
  else
    USE_CONDA=1
  fi
fi

if [[ "${USE_CONDA}" -eq 1 ]]; then
  ARCH="$(uname -m)"
  MINICONDA_DIR="${PROJECT_ROOT}/.miniconda"
  if [[ ! -d "${MINICONDA_DIR}" ]]; then
    log "Installing local Miniconda to ${MINICONDA_DIR} ..."
    if [[ "${ARCH}" == "arm64" ]]; then
      CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-arm64.sh"
    else
      CONDA_URL="https://repo.anaconda.com/miniconda/Miniconda3-latest-MacOSX-x86_64.sh"
    fi
    curl -L -o Miniconda3.sh "${CONDA_URL}"
    bash Miniconda3.sh -b -p "${MINICONDA_DIR}"
    rm -f Miniconda3.sh
  fi
  # shellcheck disable=SC1091
  source "${MINICONDA_DIR}/etc/profile.d/conda.sh"
  # Accept Anaconda TOS for default channels (non-interactive)
  conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main || true
  conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r || true
  conda create -y -n lam_a2e python=3.10
  # shellcheck disable=SC1091
  source "${MINICONDA_DIR}/etc/profile.d/conda.sh"
  conda activate lam_a2e
  PYTHON_BIN="python"
  log "Using Conda env: lam_a2e"
fi

log "Using Python: ${PYTHON_BIN} ($(${PYTHON_BIN} -V))"

# If using python3.10 binary, create venv
VENV_DIR="${PROJECT_ROOT}/.venv310"
if [[ "${PYTHON_BIN}" != "python" ]]; then
  if [[ ! -d "${VENV_DIR}" ]]; then
    log "Creating virtual environment at ${VENV_DIR} ..."
    "${PYTHON_BIN}" -m venv "${VENV_DIR}"
  fi
  # shellcheck disable=SC1091
  source "${VENV_DIR}/bin/activate"
  PYTHON_BIN="python"
  log "Venv activated: ${VENV_DIR}"
fi

# 3) Upgrade pip & install deps
${PYTHON_BIN} -m pip install --upgrade pip wheel setuptools

# Local wheel for WebGL render
if [[ -f "${PROJECT_ROOT}/wheels/gradio_gaussian_render-0.0.3-py3-none-any.whl" ]]; then
  log "Installing gradio_gaussian_render wheel ..."
  ${PYTHON_BIN} -m pip install "${PROJECT_ROOT}/wheels/gradio_gaussian_render-0.0.3-py3-none-any.whl"
else
  warn "gradio_gaussian_render wheel missing; continuing without it."
fi

# Project requirements
log "Installing project requirements ..."
${PYTHON_BIN} -m pip install -r requirements.txt

# PyTorch for macOS CPU/MPS
log "Installing PyTorch (CPU/MPS) ..."
${PYTHON_BIN} -m pip install torch torchvision torchaudio

# Allow MPS fallback if some ops are missing
export PYTORCH_ENABLE_MPS_FALLBACK=1

# 4) Ensure assets & pretrained models exist
if [[ ! -f "assets/sample_audio/BarackObama_english.wav" ]]; then
  log "Assets missing. Downloading ..."
  curl -L -o LAM_audio2exp_assets.tar "https://virutalbuy-public.oss-cn-hangzhou.aliyuncs.com/share/aigc3d/data/LAM/LAM_audio2exp_assets.tar"
  tar -xzvf LAM_audio2exp_assets.tar && rm -f LAM_audio2exp_assets.tar
fi

if [[ ! -f "pretrained_models/lam_audio2exp_streaming.tar" ]]; then
  log "Pretrained model missing. Downloading ..."
  curl -L -o LAM_audio2exp_streaming.tar "https://virutalbuy-public.oss-cn-hangzhou.aliyuncs.com/share/aigc3d/data/LAM/LAM_audio2exp_streaming.tar"
  tar -xzvf LAM_audio2exp_streaming.tar && rm -f LAM_audio2exp_streaming.tar
fi

# 5) Launch Gradio app
log "Starting Gradio app (app_lam_audio2exp.py) ..."
${PYTHON_BIN} app_lam_audio2exp.py