# Emergency care capacity planning in PACA

---

## Description

This project analyzes the **fragility of hospital emergency services in the PACA region** over the period 2015–2023, and makes a recommendation to the ARS PACA on the priority of action to be retained for the 2025–2027 horizon.
It mobilizes four prospective methods:

- **Diagnostic method**: trend analysis + detection of structural rupture (PELT, Chow test)

- **Enlargement method**: horizon scanning (4 signals + signpost table)

- **Test method**: Monte Carlo simulation (N = 10,000, horizon 2024–2027)

- **Scenarios**: construction of 4 coherent worlds + final recommendation

---

## Structure of the deposit

```
├── README.md
├── scripts/
│   └── DADEE_Project_Code_Sedjro_Khadidjatou.R       
├── figures/                       
│   ├── fig1_passages_paca.png
│   ├── fig2_ratio_passages_lits.png
│   ├── fig3_detection_rupture.png
│   ├── fig4_fragilite_dep.png
│   └── fig5_montecarlo.png
└── data/
    └── raw/                       
        ├── CAPACT_PM_PNM/
        └── urgences_2023_structure.csv
```

---

## Data

### 1. SAE statistical bases — CAPACT_PM_PNM

| | |
|---|---|
| **Source** | DREES |
| **URL** | https://data.drees.solidarites-sante.gouv.fr/explore/dataset/708_bases-statistiques-sae/ |
| **File to download** | `CAPACT_PM_PNM.7z` (Attachments) |
| **Contenu** | Activity and capacity of all health facilities, 2000–2024 |
| **Table used** | `capact0024.csv` |
| **Filter applied** |Region = `"93"` (PACA), discipline = `"21100"` (Medicine), years 2015–2023|

> ⚠️ The `.7z` file requires compatible software: **The Unarchiver** (Mac) or **7-Zip** (Windows).

### 2. Emergency Survey 2023 — Structure component

| | |
|---|---|
| **Source** | DREES |
| **URL** | https://data.drees.solidarites-sante.gouv.fr/explore/dataset/507_l-enquete-nationale-sur-les-structures-des-urgences-hospitalieres/ |
| **File to download** | CSV Component Structure 2023 (attachments) |
| **Contenu** | Organization of the 719 reception points at the emergency room in France, June 2023 |
| **Filter applied** | Départements PACA : 04, 05, 06, 13, 83, 84 |

---

## Reproduction of results

### Prerequisites

- Packages R :

```r
install.packages(c("tidyverse", "ggplot2", "scales", "strucchange", "changepoint"))
```

### Steps

**Step 1 — Download and unzip data**

Place the files in `data/raw/` according to the structure above.

**Step 2 — Adapt the paths in the script**

Open `scripts/DADEE_Project_Code_Sedjro_Khadidjatou.R` and modify the following two lines:

```r
path_capact   <- "/path/to/CAPACT_PM_PNM"
path_struct23 <- "/path/to/emergencies_2023_structure.csv"
```

**Step 3 — Launch the script**

```r
source("scripts/DADEE_Project_Code_Sedjro_Khadidjatou.R")
```

All figures are automatically saved in the work folder.

---

## Main results

| Indicators | Value |
|---|---|
| Visits to the emergency room PACA 2015 | 1 730 852 |
| Visits to the PACA emergency room 2019 | 1 886 130 |
| Variation 2015–2019 | +9,0% |
| COVID 2020 shock | −17,3% |
|2022 passages/beds ratio| **200** (Historical maximum) |
| Decrease in beds 2019–2023 | −2,4% |
| Structural rupture detected | **2020** (PELT + Chow, p = 0,051) |
| PACA reception points with access regulation| **23,6%** |
| Median projection passages 2027 | 1 957 146 |
| Projection P90 passages 2027 | 2 000 946 |

---

## Figures

| Figure | Description |
|---|---|
| `fig1_passages_paca.png` | Passages to the PACA emergency room 2015–2023 |
| `fig2_ratio_passages_lits.png` | Passages/bed ratio — voltage indicator |
| `fig3_detection_rupture.png` | PELT rupture detection|
| `fig4_fragilite_dep.png` | Structural fragility by department (Emergency Survey 2023) |
| `fig5_montecarlo.png` | Projections Monte Carlo 2024–2027 with decision horizon |

---

## Recommandation
The analysis leads to recommending the ARS PACA to **prioritize the strengthening of coordination with the downstream hospital services** the only robust action in all the scenarios considered before any heavy investment in surge capacity.
Schedule :
- **End of 2025** : Deployment of real-time bed management tools (Alpes-de-Haute-Provence and Var as a priority)
- **End of 2026** : Accelerated transfer protocols + regional pool of caregiver replacements
- **From 2027** : Revaluation of surge investments based on monitoring indicators

---

## References

- DREES (2024). *Enquête nationale sur les structures des urgences hospitalières 2023*. Études et Résultats n°1305.
- DREES (2025). *Bases statistiques SAE — CAPACT_PM_PNM 2000–2024*. data.drees.solidarites-sante.gouv.fr.
- INSEE (2021). *Projections de population à l'horizon 2070*. INSEE Première n°1881.
- LFSS (2024). *Loi de financement de la sécurité sociale 2024*, Article 51. Journal Officiel.
- Moskop J.C. et al. (2009). "Crowding, boarding, and after-hours surges in emergency medicine". *Academic Emergency Medicine*, 16(1), 1–3.

---

