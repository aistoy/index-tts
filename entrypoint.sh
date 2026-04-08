#!/bin/bash
set -e

VENV_DIR="/data/venv"
CHECKPOINTS_DIR="/data/checkpoints"
HF_CACHE_DIR="/data/hf_cache"
APP_DIR="/app"

# HF 镜像（国内服务器无法直连 huggingface.co）
export HF_ENDPOINT="${HF_ENDPOINT:-https://hf-mirror.com}"
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

# ========== 2. 下载主模型（从 ModelScope） ==========
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

# ========== 3. 预下载 HF 子模型（通过镜像） ==========
# infer_v2.py 运行时会自动下载以下模型，此处预下载以避免启动时网络问题
HF_MODELS=(
    "facebook/w2v-bert-2.0"
    "amphion/MaskGCT"
    "funasr/campplus"
    "nvidia/bigvgan_v2_22khz_80band_256x"
)

echo "========== 检查 HF 子模型缓存 =========="
for model_id in "${HF_MODELS[@]}"; do
    echo "  检查 $model_id ..."
    python -c "
from huggingface_hub import snapshot_download
snapshot_download('$model_id', local_files_only=True)
" 2>/dev/null && echo "  ✅ $model_id 已缓存" || {
        echo "  📥 下载 $model_id ..."
        python -c "
from huggingface_hub import snapshot_download
snapshot_download('$model_id')
"
        echo "  ✅ $model_id 下载完成"
    }
done

# ========== 4. 启动 WebUI ==========
exec python "$APP_DIR/webui.py" \
    --host "${HOST:-0.0.0.0}" \
    --port "${PORT:-7860}" \
    --model_dir "$CHECKPOINTS_DIR" \
    --fp16
