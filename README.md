# Planification de la capacité des soins d'urgence en PACA
### DADEE — Prospective Methods for Economic Decision-Making — Topic 6
**M2 DADEE, Aix-Marseille School of Economics — Mai 2026**

---

## Description

Ce projet analyse la **fragilité des services d'urgences hospitalières en région PACA** sur la période 2015–2023, et formule une recommandation à l'ARS PACA sur la priorité d'action à retenir pour l'horizon 2025–2027.

Il mobilise quatre méthodes prospectives :
- **Méthode diagnostique** : analyse de tendance + détection de rupture structurelle (PELT, test de Chow)
- **Méthode d'élargissement** : horizon scanning (4 signaux + tableau de signposts)
- **Méthode de test** : simulation Monte Carlo (N = 10 000, horizon 2024–2027)
- **Scénarios** : construction de 4 mondes cohérents + recommandation finale

---

## Structure du dépôt

```
├── README.md
├── scripts/
│   └── DADEE_script_final.R       # Script R unique — tous les résultats
├── figures/                       # Figures générées (à créer en lançant le script)
│   ├── fig1_passages_paca.png
│   ├── fig2_ratio_passages_lits.png
│   ├── fig3_detection_rupture.png
│   ├── fig4_fragilite_dep.png
│   └── fig5_montecarlo.png
└── data/
    └── raw/                       # Données brutes (non versionnées — voir ci-dessous)
        ├── CAPACT_PM_PNM/
        └── urgences_2023_structure.csv
```

> ⚠️ **Les données brutes ne sont pas versionnées** (taille trop importante). Voir la section **Données** ci-dessous pour les télécharger.

---

## Données

### 1. Bases statistiques SAE — CAPACT_PM_PNM

| | |
|---|---|
| **Source** | DREES |
| **URL** | https://data.drees.solidarites-sante.gouv.fr/explore/dataset/708_bases-statistiques-sae/ |
| **Fichier à télécharger** | `CAPACT_PM_PNM.7z` (pièces jointes) |
| **Contenu** | Activité et capacités de tous les établissements de santé, 2000–2024 |
| **Table utilisée** | `capact0024.csv` |
| **Filtre appliqué** | région = `"93"` (PACA), discipline = `"21100"` (Médecine), années 2015–2023 |
| **Licence** | Licence Ouverte 2.0 (Etalab) |

> ⚠️ Le fichier `.7z` nécessite un logiciel compatible : **The Unarchiver** (Mac) ou **7-Zip** (Windows).

### 2. Enquête Urgences 2023 — volet Structure

| | |
|---|---|
| **Source** | DREES |
| **URL** | https://data.drees.solidarites-sante.gouv.fr/explore/dataset/507_l-enquete-nationale-sur-les-structures-des-urgences-hospitalieres/ |
| **Fichier à télécharger** | CSV volet Structure 2023 (pièces jointes) |
| **Contenu** | Organisation des 719 points d'accueil aux urgences de France, juin 2023 |
| **Filtre appliqué** | Départements PACA : 04, 05, 06, 13, 83, 84 |
| **Licence** | Licence Ouverte 2.0 (Etalab) |

---

## Reproduction des résultats

### Prérequis

- R >= 4.2
- Packages R :

```r
install.packages(c("tidyverse", "ggplot2", "scales", "strucchange", "changepoint"))
```

### Étapes

**Étape 1 — Télécharger et dézipper les données**

Placer les fichiers dans `data/raw/` selon la structure ci-dessus.

**Étape 2 — Adapter les chemins dans le script**

Ouvrir `scripts/DADEE_script_final.R` et modifier les deux lignes suivantes :

```r
path_capact   <- "/chemin/vers/CAPACT_PM_PNM"
path_struct23 <- "/chemin/vers/urgences_2023_structure.csv"
```

**Étape 3 — Lancer le script**

```r
source("scripts/DADEE_script_final.R")
```

Ou dans RStudio : ouvrir le script et appuyer sur `Cmd+Shift+Enter` (Mac) / `Ctrl+Shift+Enter` (Windows).

Toutes les figures sont sauvegardées automatiquement dans le dossier de travail.

---

## Résultats principaux

| Indicateur | Valeur |
|---|---|
| Passages aux urgences PACA 2015 | 1 730 852 |
| Passages aux urgences PACA 2019 | 1 886 130 |
| Variation 2015–2019 | +9,0% |
| Choc COVID 2020 | −17,3% |
| Ratio passages/lits 2022 | **200** (maximum historique) |
| Baisse des lits 2019–2023 | −2,4% |
| Rupture structurelle détectée | **2020** (PELT + Chow, p = 0,051) |
| Points d'accueil PACA avec régulation d'accès | **23,6%** |
| Projection médiane passages 2027 | 1 957 146 |
| Projection P90 passages 2027 | 2 000 946 |

---

## Figures produites

| Figure | Description |
|---|---|
| `fig1_passages_paca.png` | Passages aux urgences PACA 2015–2023 |
| `fig2_ratio_passages_lits.png` | Ratio passages/lits — indicateur de tension |
| `fig3_detection_rupture.png` | Détection de rupture PELT |
| `fig4_fragilite_dep.png` | Fragilité structurelle par département (Enquête Urgences 2023) |
| `fig5_montecarlo.png` | Projections Monte Carlo 2024–2027 avec horizon de décision |

---

## Recommandation

L'analyse conduit à recommander à l'ARS PACA de **prioriser le renforcement de la coordination avec les services hospitaliers aval** — seule action robuste dans l'ensemble des scénarios envisagés — avant tout investissement lourd en capacités de surge.

Calendrier :
- **Fin 2025** : déploiement d'outils de gestion des lits en temps réel (Alpes-de-Haute-Provence et Var en priorité)
- **Fin 2026** : protocoles de transfert accélérés + pool régional de remplacement soignants
- **À partir de 2027** : réévaluation des investissements surge sur la base des indicateurs de monitoring

---

## Références

- DREES (2024). *Enquête nationale sur les structures des urgences hospitalières 2023*. Études et Résultats n°1305.
- DREES (2025). *Bases statistiques SAE — CAPACT_PM_PNM 2000–2024*. data.drees.solidarites-sante.gouv.fr.
- INSEE (2021). *Projections de population à l'horizon 2070*. INSEE Première n°1881.
- LFSS (2024). *Loi de financement de la sécurité sociale 2024*, Article 51. Journal Officiel.
- Moskop J.C. et al. (2009). "Crowding, boarding, and after-hours surges in emergency medicine". *Academic Emergency Medicine*, 16(1), 1–3.

---

## Licence

Données sources : Licence Ouverte 2.0 (Etalab) — réutilisation libre avec mention de la source.
