# ============================================================
# IndexTTS2 Dockerfile
# 运行 IndexTTS2 WebUI，支持 GPU 加速推理
#
# 构建命令：
#   docker build -t indextts2 .
#
# 运行命令（GPU）：
#   docker run --gpus all -p 7860:7860 indextts2
# ============================================================

FROM nvidia/cuda:12.8.0-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1

RUN apt-get update && apt-get install -y --no-install-recommends \
        python3.10 python3.10-venv python3-pip \
        git git-lfs sox libsox-dev \
        ffmpeg libsndfile1 \
    && rm -rf /var/lib/apt/lists/* \
    && ln -sf /usr/bin/python3.10 /usr/bin/python \
    && ln -sf /usr/bin/python3.10 /usr/bin/python3

# 安装 uv 包管理器
RUN pip install --no-cache-dir uv

WORKDIR /app

# 复制项目源码
COPY . .

# 创建虚拟环境并安装依赖
RUN uv venv /app/.venv --python 3.10 \
    && . /app/.venv/bin/activate \
    && uv sync --extra webui --frozen

# HF 镜像（构建时使用，运行时继承）
ENV HF_ENDPOINT=https://hf-mirror.com

# 下载主模型（ModelScope）
RUN . /app/.venv/bin/activate \
    && python -c "from modelscope import snapshot_download; snapshot_download('IndexTeam/IndexTTS-2', local_dir='/app/checkpoints')"

# 预下载 HF 子模型（通过镜像）
RUN . /app/.venv/bin/activate \
    && python -c "
from huggingface_hub import snapshot_download
for m in ['facebook/w2v-bert-2.0', 'amphion/MaskGCT', 'funasr/campplus', 'nvidia/bigvgan_v2_22khz_80band_256x']:
    print(f'Downloading {m}...')
    snapshot_download(m)
    print(f'Done: {m}')
"

# 创建必要目录
RUN mkdir -p /app/outputs/tasks /app/prompts

EXPOSE 7860

CMD ["/app/.venv/bin/python", "webui.py", "--host", "0.0.0.0", "--port", "7860", "--fp16"]
