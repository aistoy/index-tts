# ============================================================
# IndexTTS2 Dockerfile
# 运行 IndexTTS2 WebUI，支持 GPU 加速推理
#
# 构建命令：
#   docker build -t indextts2 .
#
# 运行命令（GPU，venv 和模型持久化到宿主机）：
#   docker run --gpus all -p 7860:7860 \
#     -v /path/to/data:/data indextts2
#
# 运行命令（不持久化，每次重建 venv）：
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

# 仅复制项目源码（venv 和模型在运行时按需创建/下载）
COPY . .

RUN chmod +x /app/entrypoint.sh

# /data 用于持久化 venv 和 checkpoints（通过 -v 挂载）
VOLUME ["/data"]

EXPOSE 7860

ENTRYPOINT ["/app/entrypoint.sh"]
