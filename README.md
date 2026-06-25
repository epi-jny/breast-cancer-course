# Breast Cancer Course — Deep Learning sur mammographies

Cours pratique en 6 chapitres, du PyTorch de base jusqu'au **contrôle de risque
garanti** (abstention / selective classification), appliqué à la détection du
cancer du sein sur mammographies (jeu de données **RSNA**).

Chaque chapitre est un **notebook Jupyter qui exécute réellement du code** : il
entraîne de vrais réseaux, télécharge des jeux de données, et reproduit les
résultats. Tout est packagé dans une **image Docker** qui embarque l'environnement
GPU complet, et qui clone automatiquement les deux dépôts externes utilisés
(`GMIC` et `selective-classification`) — vous n'avez rien à récupérer à la main.

---

## Les chapitres

| # | Notebook | Sujet | GPU |
|---|----------|-------|-----|
| 1 | `notebooks/01_download_data.ipynb` | **Télécharger les données RSNA via la clé Kaggle** (prérequis aux ch. 2.5→5) | non |
| 2 | `notebooks/02_pytorch_basics.ipynb` | PyTorch de base : tenseurs, autograd, un réseau de vision simple | non (CPU OK) |
| 2.5 | `notebooks/02.5_preprocessing.ipynb` | Pré-traitement des mammographies : DICOM → PNG, crop, conversions qui libèrent le CPU (ne laisser que le décodage) | recommandé |
| 3 | `notebooks/03_resnet18_breast_density.ipynb` | Entraînement multiclasse avec un réseau connu (ResNet-18) — cas d'usage : **densité mammaire** | oui |
| 4 | `notebooks/04_gmic_architecture.ipynb` | Architecture d'un réseau récent : **GMIC** (ensemble de réseaux) — cas d'usage : **cancer malin RSNA** | oui |
| 5 | `notebooks/05_gmic_finetuning.ipynb` | Fine-tuning de GMIC sur RSNA | oui |
| 6 | `notebooks/06_risk_control_abstention.ipynb` | **Risques garantis** (selective classification, papier Beyond Accuracy) et comment appliquer ces fonctions | non (CPU OK) |

> Le chapitre 2 et le chapitre 6 peuvent tourner sur une machine sans GPU
> puissant. Les chapitres 2.5 à 5 supposent un GPU NVIDIA (entraînements réels).

---

## Prérequis (à régler **avant** de construire l'image)

1. **Une machine avec un GPU NVIDIA** + pilotes, `docker`, et le
   `nvidia-container-toolkit` (pour `docker run --gpus all`).
2. **Accès au démon Docker** : votre utilisateur doit pouvoir lancer `docker`
   (membre du groupe `docker`, ou `sudo docker`, ou Docker rootless).
3. **Une clé d'API Kaggle** (pour télécharger le jeu RSNA). Voir
   [Configuration Kaggle](#configuration-kaggle) — c'est la chose à ne pas
   oublier sinon les notebooks de téléchargement échoueront.

Les données RSNA (~300 Go) ne sont **jamais** dans l'image : elles sont
téléchargées par les notebooks dans un volume monté (`~/data`), donc elles
persistent entre deux `docker run`.

---

## Démarrage rapide

```bash
# 1. Cloner ce dépôt sur la machine puissante
git clone git@github.com:epi-jny/breast-cancer-course.git
cd breast-cancer-course

# 2. Configurer Kaggle (voir section dédiée) — une seule fois
#    => place kaggle.json dans ~/.kaggle/ sur la machine hôte

# 3. Construire l'image (clone GMIC + selective-classification, installe tout)
./docker-build.sh          # = docker build -t breast-cancer-course:latest .

# 4. Lancer JupyterLab dans le conteneur (GPU + volumes montés)
./docker-run.sh            # écoute sur 127.0.0.1:8888 DANS la VM

# 5. Depuis votre laptop, ouvrir un tunnel SSH vers la VM puis le navigateur
ssh -L 8888:localhost:8888 <votre-alias-vm>
#    puis ouvrir http://localhost:8888 dans le navigateur du laptop
```

Le kernel Jupyter (donc les entraînements) s'exécute **dans le conteneur sur la
VM**, avec le GPU. Le tunnel SSH ne transporte que l'interface web.

Une fois dans JupyterLab, commencez par **`notebooks/01_download_data.ipynb`**
pour récupérer le jeu RSNA via la clé Kaggle, puis suivez les chapitres dans
l'ordre.

---

## Configuration Kaggle

Les notebooks téléchargent le jeu RSNA via l'API Kaggle. Il faut fournir des
identifiants Kaggle **à l'hôte**, montés en lecture seule dans le conteneur (ils
ne sont **pas** copiés dans l'image, pour ne pas y laisser de secret).

1. Sur [kaggle.com](https://www.kaggle.com) → *Account* → *Create New API Token*
   → télécharge `kaggle.json`.
2. Sur la machine hôte :
   ```bash
   mkdir -p ~/.kaggle
   mv kaggle.json ~/.kaggle/kaggle.json
   chmod 600 ~/.kaggle/kaggle.json
   ```
3. `docker-run.sh` monte `~/.kaggle` dans le conteneur automatiquement.

Vous pouvez aussi copier `.env.example` en `.env` et y mettre
`KAGGLE_USERNAME`/`KAGGLE_KEY` (lus au `docker run` via `--env-file`).

---

## Ce que fait l'image Docker

- Base : `pytorch/pytorch:2.4.1-cuda12.1-cudnn9-runtime` (même stack torch que la VM).
- **Clone automatiquement** au build :
  - [`nyukat/GMIC`](https://github.com/nyukat/GMIC) → `/root/GMIC` (inclut les 5 poids `sample_model_*.p`).
  - [`EmilienJemelen/selective-classification`](https://github.com/EmilienJemelen/selective-classification) → `/root/selective-classification`.
- Installe les dépendances Python des 6 chapitres (`requirements.txt`).
- Copie les notebooks dans `/root/course/notebooks` (re-montés en volume au run
  pour édition à chaud).
- Démarre JupyterLab sur le port 8888.

Au runtime, `docker-run.sh` monte :

| Hôte | Conteneur | Rôle |
|------|-----------|------|
| `~/data` | `/root/data` | jeux de données téléchargés (persistants) |
| `~/.kaggle` | `/root/.kaggle` (ro) | identifiants Kaggle |
| `./notebooks` | `/root/course/notebooks` | édition des notebooks sans rebuild |

---

## Structure du dépôt

```
breast-cancer-course/
├── README.md              # ce fichier
├── Dockerfile             # image GPU + clone GMIC/selective-classification
├── requirements.txt       # dépendances Python curées des 6 chapitres
├── docker-build.sh        # construit l'image
├── docker-run.sh          # lance JupyterLab (GPU + volumes)
├── .env.example           # gabarit pour les identifiants Kaggle
└── notebooks/             # les 6 chapitres
```
