#!/bin/bash
set -e

CHECKPOINTS_DIR="${MODEL_DIR:-/app/checkpoints}"

# 检查模型是否已存在（检测关键文件 gpt.pth）
if [ ! -f "$CHECKPOINTS_DIR/gpt.pth" ]; then
    echo "========== 模型文件不存在，从 ModelScope 下载 IndexTTS-2 =========="
    /app/.venv/bin/python -c "
from modelscope import snapshot_download
snapshot_download('IndexTeam/IndexTTS-2', local_dir='$CHECKPOINTS_DIR')
"
    echo "========== 模型下载完成 =========="
else
    echo "========== 检测到已有模型文件，跳过下载 =========="
fi

# 启动 WebUI
exec /app/.venv/bin/python webui.py \
    --host "${HOST:-0.0.0.0}" \
    --port "${PORT:-7860}" \
    --model_dir "$CHECKPOINTS_DIR" \
    --fp16
