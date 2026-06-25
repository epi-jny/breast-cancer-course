#!/usr/bin/env bash
# Lance JupyterLab dans le conteneur, sur le GPU, avec les volumes montés.
# JupyterLab écoute sur 127.0.0.1:8888 de la machine hôte (la VM).
# Depuis le laptop : ssh -L 8888:localhost:8888 <alias-vm>  puis  http://localhost:8888
set -euo pipefail

IMAGE="${IMAGE:-breast-cancer-course:latest}"
DATA_DIR="${DATA_DIR:-$HOME/data}"
KAGGLE_DIR="${KAGGLE_DIR:-$HOME/.kaggle}"

cd "$(dirname "$0")"
mkdir -p "$DATA_DIR"

ENV_ARGS=()
[ -f .env ] && ENV_ARGS+=(--env-file .env)

KAGGLE_ARGS=()
[ -d "$KAGGLE_DIR" ] && KAGGLE_ARGS+=(-v "$KAGGLE_DIR":/root/.kaggle:ro)

docker run --rm -it \
    --gpus all \
    -p 127.0.0.1:8888:8888 \
    -v "$DATA_DIR":/root/data \
    -v "$PWD/notebooks":/root/course/notebooks \
    "${KAGGLE_ARGS[@]}" \
    "${ENV_ARGS[@]}" \
    "$IMAGE"
