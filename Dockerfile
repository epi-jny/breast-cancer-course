# Breast Cancer Course — image GPU + JupyterLab
#
# Même stack torch que la VM (torch 2.4.1 / cu121 / torchvision 0.19.1).
# L'image clone elle-même GMIC et selective-classification : rien à fournir
# à la main. Les DONNÉES ne sont jamais dans l'image (montées en volume).

FROM pytorch/pytorch:2.4.1-cuda12.1-cudnn9-runtime

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Dépendances système :
#  - git    : pour cloner GMIC + selective-classification
#  - libgl1 / libglib2.0-0 : requis par opencv pour le pré-traitement (ch 2.5)
RUN apt-get update && apt-get install -y --no-install-recommends \
        git \
        libgl1 \
        libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root

# Clone des deux dépôts externes. GMIC embarque ses 5 poids pré-entraînés
# (models/sample_model_*.p, ~60 Mo chacun) directement dans le dépôt git.
# On échoue explicitement si les poids manquent après le clone.
RUN git clone --depth 1 https://github.com/nyukat/GMIC.git /root/GMIC \
    && git clone --depth 1 https://github.com/EmilienJemelen/selective-classification.git /root/selective-classification \
    && test -f /root/GMIC/models/sample_model_1.p \
        || (echo "ERREUR: poids GMIC absents après le clone" && exit 1)

# Dépendances Python des 6 chapitres (torch/torchvision viennent de l'image de base).
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# Contenu du cours (re-monté en volume au runtime pour édition à chaud).
COPY notebooks /root/course/notebooks
COPY README.md /root/course/README.md

WORKDIR /root/course

EXPOSE 8888

# Accès via tunnel SSH vers 127.0.0.1 → token désactivé (réseau local au tunnel).
# root_dir=/root pour que GMIC, selective-classification et data soient visibles
# dans l'explorateur de fichiers JupyterLab.
CMD ["jupyter", "lab", \
     "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", \
     "--ServerApp.token=", "--ServerApp.password=", \
     "--ServerApp.root_dir=/root"]
