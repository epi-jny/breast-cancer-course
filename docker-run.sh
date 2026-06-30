#!/usr/bin/env bash
# Lance JupyterLab dans le conteneur, sur le GPU, avec le DÉPÔT entier monté.
# JupyterLab écoute sur 127.0.0.1:8888 de la machine hôte (la VM).
# Depuis le laptop : ssh -L 8888:localhost:8888 <alias-vm>  puis  http://localhost:8888
#
# Aucun chemin n'est codé en dur : tout part de l'endroit où ce script (donc le
# dépôt) a été cloné. On NE dépend PAS de $HOME.
set -euo pipefail

# Racine du dépôt = dossier de ce script, résolu en chemin absolu.
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$REPO_DIR"

IMAGE="${IMAGE:-breast-cancer-course:latest}"
# Point de montage du dépôt dans le conteneur (= COURSE_ROOT de l'image).
COURSE_MNT="/home/deep-piste/course"

# Les notebooks lisent GMIC/selective-classification depuis modules/. Si les
# sous-modules ne sont pas initialisés, on le fait maintenant.
if [ ! -f modules/GMIC/models/sample_model_1.p ]; then
    echo ">> Sous-modules non initialisés -> git submodule update --init --recursive"
    git submodule update --init --recursive
fi

# Identifiants Kaggle, relatifs au dépôt (jamais via $HOME) : le dossier .kaggle/
# (versionné dans le dépôt) où l'utilisateur dépose son token, monté en lecture seule
# sur /home/deep-piste/.kaggle. La clé est ignorée par git.
#   - access_token : token récent KGAT_ (recommandé ; le seul qui marche avec kaggle 2.x)
#   - kaggle.json  : ancien format username + key
mkdir -p "$REPO_DIR/.kaggle"
KAGGLE_ARGS=(-v "$REPO_DIR/.kaggle":/home/deep-piste/.kaggle:ro)

if [ ! -f "$REPO_DIR/.kaggle/access_token" ] && [ ! -f "$REPO_DIR/.kaggle/kaggle.json" ]; then
    echo "AVERTISSEMENT : aucun identifiant Kaggle dans $REPO_DIR/.kaggle/" >&2
    echo "  -> dépose ton token dans .kaggle/access_token (recommandé) ou un kaggle.json," >&2
    echo "     sinon le téléchargement (ch1) échouera." >&2
fi

echo "Montage du dépôt : $REPO_DIR -> $COURSE_MNT"

docker run --rm -it \
    --gpus all \
    -p 127.0.0.1:8888:8888 \
    -v "$REPO_DIR":"$COURSE_MNT" \
    "${KAGGLE_ARGS[@]}" \
    "$IMAGE"
