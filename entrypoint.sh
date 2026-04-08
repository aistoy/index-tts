#!/bin/bash
set -e

VENV_DIR="/data/venv"
CHECKPOINTS_DIR="/data/checkpoints"
HF_CACHE_DIR="/data/hf_cache"
APP_DIR="/app"

# HF 子模型缓存持久化到 /data，避免每次重启重复下载
export HF_HUB_CACHE="$HF_CACHE_DIR"
mkdir -p "$HF_CACHE_DIR"

# ========== 1. 创建虚拟环境并安装依赖 ==========
if [ ! -f "$VENV_DIR/bin/python" ]; then
    echo "========== 虚拟环境不存在，开始创建并安装依赖 =========="
    uv venv "$VENV_DIR" --python 3.10
    . "$VENV_DIR/bin/activate"
    uv sync --extra webui --frozen
    echo "========== 依赖安装完成 =========="
else
    echo "========== 检测到已有虚拟环境，跳过安装 =========="
    . "$VENV_DIR/bin/activate"
fi

# ========== 2. 下载模型（从 ModelScope） ==========
if [ ! -f "$CHECKPOINTS_DIR/gpt.pth" ]; then
    echo "========== 模型文件不存在，从 ModelScope 下载 IndexTTS-2 =========="
    python -c "
from modelscope import snapshot_download
snapshot_download('IndexTeam/IndexTTS-2', local_dir='$CHECKPOINTS_DIR')
"
    echo "========== 模型下载完成 =========="
else
    echo "========== 检测到已有模型文件，跳过下载 =========="
fi

# ========== 3. 启动 WebUI ==========
exec python "$APP_DIR/webui.py" \
    --host "${HOST:-0.0.0.0}" \
    --port "${PORT:-7860}" \
    --model_dir "$CHECKPOINTS_DIR" \
    --fp16
