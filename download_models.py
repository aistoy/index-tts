"""构建时预下载 HF 子模型"""
from huggingface_hub import snapshot_download

models = [
    "facebook/w2v-bert-2.0",
    "amphion/MaskGCT",
    "funasr/campplus",
    "nvidia/bigvgan_v2_22khz_80band_256x",
]

for m in models:
    print(f"Downloading {m}...")
    snapshot_download(m)
    print(f"Done: {m}")
