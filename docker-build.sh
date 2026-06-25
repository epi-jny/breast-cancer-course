#!/usr/bin/env bash
# Construit l'image du cours. Clone GMIC + selective-classification et installe
# tout l'environnement. Aucune donnée n'est intégrée à l'image.
set -euo pipefail

IMAGE="${IMAGE:-breast-cancer-course:latest}"

cd "$(dirname "$0")"
echo ">> docker build -t ${IMAGE} ."
docker build -t "${IMAGE}" .
echo ">> Image construite : ${IMAGE}"
