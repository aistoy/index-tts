# ============================================================
# IndexTTS2 Dockerfile
# 运行 IndexTTS2 WebUI，支持 GPU 加速推理
#
# 构建命令：
#   docker build -t indextts2 .
#
# 运行命令（GPU）：
#   docker run --gpus all -p 7860:7860 indextts2
#
# 运行命令（CPU，较慢）：
#   docker run -p 7860:7860 indextts2
# ============================================================

FROM nvidia/cuda:12.8.0-runtime-ubuntu22.04 AS base

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

# 复制全部项目文件（hatchling 构建 editable 包需要 README.md 等文件）
COPY . .

# 使用 uv 创建虚拟环境并安装依赖
# 仅安装 webui extra，跳过 deepspeed（编译需要 nvcc，runtime 镜像不包含）
RUN uv venv /app/.venv --python 3.10 \
    && . /app/.venv/bin/activate \
    && uv sync --extra webui --frozen

# 下载 IndexTTS2 模型权重到 checkpoints 目录
# 如果构建时网络不佳，可预先下载模型并挂载到容器中
RUN --mount=type=cache,target=/root/.cache/huggingface \
    . /app/.venv/bin/activate \
    && python -c "from huggingface_hub import snapshot_download; snapshot_download('IndexTeam/IndexTTS-2', local_dir='/app/checkpoints')"

# 创建必要目录
RUN mkdir -p /app/outputs/tasks /app/prompts

EXPOSE 7860

# 默认使用 FP16 推理以节省显存，监听所有网卡
CMD ["/app/.venv/bin/python", "webui.py", "--host", "0.0.0.0", "--port", "7860", "--fp16"]
