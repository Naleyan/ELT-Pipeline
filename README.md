📊 GitHub Analytics ELT Pipeline

Ce projet implémente un pipeline ELT (Extract-Load-Transform) complet pour analyser la santé et la maturité de dépôts open-source populaires. Il utilise l'architecture Medallion pour transformer les données brutes de l'API GitHub en un système de scoring décisionnel.

🏗️ Architecture du Projet

Le projet est structuré selon les trois couches de l'architecture Medallion :

Bronze (Raw) : Ingestion des données brutes depuis l'API GitHub vers DuckDB via un script Python. Les données sont stockées telles quelles pour garantir la traçabilité.

Silver (Staging) : Nettoyage, typage des données (casting), normalisation et création de colonnes dérivées (ex: calcul de l'âge du repo, durée de fusion des PRs).

Gold (Business) : Modélisation en Schéma en Étoile (Star Schema) composée de tables de dimensions et de faits, aboutissant à une table de scoring finale.

🛠️ Stack Technique

Transformation : dbt-core (v1.9+)

Base de données : DuckDB (moteur OLAP local)

Langage : Python 3.9+ (pour l'ingestion) et SQL (Jinja) pour les modèles dbt.

Adaptateur : dbt-duckdb

📂 Structure du Projet dbt

github_analytics/
├── models/
│   ├── bronze/          # Déclaration des sources raw
│   ├── silver/          # Modèles stg_* (nettoyage & typing)
│   └── gold/            # Dimensions, Faits et Scoring
├── snapshots/           # Historisation SCD Type 2 des métriques
├── tests/               # Tests singuliers (logique métier)
└── scripts/             # Scripts d'ingestion Python


🚀 Installation et Utilisation

1. Préparation de l'environnement

# Créer et activer l'environnement virtuel
python3.12 -m venv .venv
source .venv/bin/activate

# Installer les dépendances
pip install dbt-core dbt-duckdb


2. Configuration du profil

Le fichier ~/.dbt/profiles.yml doit être configuré comme suit :

github_analytics:
  target: dev
  outputs:
    dev:
      type: duckdb
      path: "github_analytics.duckdb"
      threads: 4


3. Exécution du pipeline

# Charger les données brutes dans la couche Bronze
python scripts/load_bronze.py

# Lancer les transformations dbt
dbt run

# Exécuter les tests de qualité
dbt test

# Générer les snapshots (historique des stars/forks)
dbt snapshot


📊 Méthodologie de Scoring (Couche Gold)

La table scoring_repositories calcule un score global (0-100) basé sur une moyenne pondérée de 4 axes :

Popularité (20%) : Stars, forks, watchers.

Activité (30%) : Commits récents, nombre de contributeurs.

Réactivité (30%) : Temps de fermeture des PRs et des issues.

Communauté (20%) : Ratio de PRs fusionnées et d'issues clôturées.

La normalisation est effectuée via la méthode NTILE pour comparer les dépôts relativement les uns aux autres.

🛡️ Qualité des Données

Le projet inclut :

Tests génériques : unique, not_null, accepted_values.

Tests singuliers : Vérification de la cohérence chronologique (closed_at > created_at) et intégrité des rankings.

Snapshots : Utilisation de la stratégie check pour capturer l'évolution quotidienne des métriques sans historique natif.

Projet réalisé dans le cadre du module Data Engineering Foundations - IMT Atlantique.