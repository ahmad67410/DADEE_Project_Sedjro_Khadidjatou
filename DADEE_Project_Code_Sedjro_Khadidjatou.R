# =============================================================================
# DADEE — Topic 6 : Planification de la capacité des soins d'urgence en PACA
# Auteurs  : Sedjro CODJO, Khadijatou LOUM
# Date     : Mai 2026


# --- 0. Packages -------------------------------------------------------------

# install.packages(c("tidyverse", "ggplot2", "scales", "strucchange", "changepoint"))

library(tidyverse)
library(ggplot2)
library(scales)
library(strucchange)
library(changepoint)

# --- Thème graphique commun --------------------------------------------------
theme_dadee <- function() {
  theme_minimal(base_size = 12) +
    theme(
      panel.grid.minor = element_blank(),
      plot.title       = element_text(face = "bold", size = 14),
      plot.subtitle    = element_text(color = "grey40", size = 11),
      legend.position  = "bottom",
      axis.text.x      = element_text(angle = 45, hjust = 1)
    )
}

# =============================================================================
# PARTIE 1 — CHARGEMENT ET NETTOYAGE SAE
# =============================================================================

# --- Adaptons ces deux chemins ------------------------------------------------
path_capact   <- "/Users/jeniocodjo/Desktop/data/CAPACT_PM_PNM"
path_struct23 <- "/Users/jeniocodjo/Desktop/data/urgences_2023_structure.csv"

# --- Chargement du fichier principal CAPACT ----------------------------------
path_csv <- file.path(path_capact, "CAPACT_PM_PNM/Bases CSV/capact0024.csv")

df <- read_delim(
  path_csv,
  delim          = ";",
  locale         = locale(encoding = "latin1", decimal_mark = ","),
  col_types      = cols(.default = "c"),
  show_col_types = FALSE
)

cat("=== Chargement SAE ===\n")
cat("Dimensions brutes :", nrow(df), "x", ncol(df), "\n")

# --- Filtrage PACA + Médecine + 2015-2023 ------------------------------------
paca <- df %>%
  filter(
    reg   == "93",      # PACA (code région INSEE)
    DISCI == "21100",   # Médecine — seule discipline avec passages urgences
    an    >= "2015",
    an    <= "2023"
  ) %>%
  mutate(
    an  = as.integer(an),
    PAS = as.numeric(PAS),   # passages aux urgences
    LIT = as.numeric(LIT)    # lits
  )

cat("Établissements PACA 2015-2023 :", n_distinct(paca$fi), "\n")
cat("Années disponibles :", sort(unique(paca$an)), "\n")

# --- Agrégat annuel PACA -----------------------------------------------------
paca_agg <- paca %>%
  group_by(an) %>%
  summarise(
    passages_total   = sum(PAS, na.rm = TRUE),
    nb_etab          = n_distinct(fi),
    lits_total       = sum(LIT, na.rm = TRUE),
    .groups          = "drop"
  ) %>%
  mutate(
    passages_par_lit = round(passages_total / lits_total, 1),
    variation_pct    = round((passages_total / lag(passages_total) - 1) * 100, 1)
  )

cat("\n=== Tableau de synthèse (Tableau 1 du papier) ===\n")
print(paca_agg %>% select(an, passages_total, lits_total, passages_par_lit, variation_pct))

# =============================================================================
# PARTIE 2 — GRAPHIQUES BASELINE
# =============================================================================

# --- Figure 1 : Passages aux urgences PACA 2015-2023 ------------------------
fig1 <- ggplot(paca_agg, aes(x = an, y = passages_total / 1e3)) +
  geom_area(fill = "#4E9AF1", alpha = 0.2) +
  geom_line(color = "#2171B5", linewidth = 1.2) +
  geom_point(color = "#2171B5", size = 3) +
  # Zone COVID
  annotate("rect",
           xmin = 2019.5, xmax = 2020.5,
           ymin = -Inf,   ymax = Inf,
           fill = "firebrick", alpha = 0.1) +
  annotate("text",
           x = 2020, y = min(paca_agg$passages_total / 1e3) * 0.98,
           label = "COVID-19", color = "firebrick", size = 3.5) +
  scale_x_continuous(breaks = 2015:2023) +
  scale_y_continuous(labels = label_number(suffix = "k")) +
  labs(
    title    = "Passages aux urgences en PACA (2015–2023)",
    subtitle = "Établissements de médecine — bases statistiques SAE",
    x        = NULL,
    y        = "Passages (milliers)",
    caption  = "Source : DREES, SAE CAPACT 2015–2023"
  ) +
  theme_dadee()

print(fig1)
ggsave("fig1_passages_paca.png", fig1, width = 8, height = 5, dpi = 150)
cat("Figure 1 sauvegardée : fig1_passages_paca.png\n")

# --- Figure 2 : Ratio passages/lits ------------------------------------------
fig2 <- ggplot(paca_agg, aes(x = an, y = passages_par_lit)) +
  geom_line(color = "#D62728", linewidth = 1.2) +
  geom_point(color = "#D62728", size = 3) +
  geom_hline(yintercept = 200, linetype = "dashed", color = "grey50") +
  annotate("text",
           x = 2015.3, y = 202,
           label = "Seuil critique : 200", size = 3, color = "grey50", hjust = 0) +
  scale_x_continuous(breaks = 2015:2023) +
  labs(
    title    = "Ratio passages / lits en PACA (2015–2023)",
    subtitle = "Indicateur de tension capacitaire",
    x        = NULL,
    y        = "Passages par lit",
    caption  = "Source : DREES, SAE CAPACT 2015–2023"
  ) +
  theme_dadee()

print(fig2)
ggsave("fig2_ratio_passages_lits.png", fig2, width = 8, height = 5, dpi = 150)
cat("Figure 2 sauvegardée : fig2_ratio_passages_lits.png\n")

# =============================================================================
# PARTIE 3 — DÉTECTION DE RUPTURE
# =============================================================================

cat("\n=== Détection de rupture ===\n")

# --- Série temporelle --------------------------------------------------------
ts_passages <- ts(paca_agg$passages_total, start = 2015, frequency = 1)

# --- PELT : détection de rupture de moyenne ----------------------------------
# PELT = Pruned Exact Linear Time : algorithme qui minimise un critère
# pénalisé (BIC) pour identifier les points de changement de régime
cpt <- cpt.mean(
  as.numeric(ts_passages),
  method    = "PELT",
  penalty   = "BIC",
  minseglen = 3
)

annee_rupture_pelt <- paca_agg$an[cpts(cpt)]
cat("Rupture(s) détectée(s) par PELT :", annee_rupture_pelt, "\n")

# --- Test de Chow : rupture structurelle en 2020 -----------------------------
paca_agg <- paca_agg %>%
  mutate(post_covid = as.integer(an >= 2020))

m_contraint <- lm(passages_total ~ an, data = paca_agg)
m_libre     <- lm(passages_total ~ an * post_covid, data = paca_agg)
test_chow   <- anova(m_contraint, m_libre)

cat("\nTest de Chow (H0 : pas de rupture en 2020) :\n")
print(test_chow)
cat(sprintf("Conclusion : p-value = %.3f → rupture %s au seuil de 10%%\n",
            test_chow$`Pr(>F)`[2],
            ifelse(test_chow$`Pr(>F)`[2] < 0.10, "significative", "non significative")))

# --- Figure 3 : Détection de rupture -----------------------------------------
png("fig3_detection_rupture.png", width = 800, height = 500)
plot(cpt,
     main = "Détection de rupture — Passages urgences PACA (2015–2023)",
     ylab = "Passages",
     xlab = "Indice temporel (1 = 2015, ..., 9 = 2023)",
     col  = "#2171B5",
     cpt.col = "firebrick",
     cpt.width = 2)
dev.off()
cat("Figure 3 sauvegardée : fig3_detection_rupture.png\n")

# =============================================================================
# PARTIE 4 — ENQUÊTE URGENCES 2023
# =============================================================================

cat("\n=== Enquête Urgences 2023 — PACA ===\n")

# --- Chargement --------------------------------------------------------------
struct23 <- read_delim(
  path_struct23,
  delim          = ";",
  locale         = locale(encoding = "latin1", decimal_mark = ","),
  col_types      = cols(.default = "c"),
  show_col_types = FALSE
)

# --- Filtrage PACA -----------------------------------------------------------
deps_paca <- c("04", "05", "06", "13", "83", "84")

struct23_paca <- struct23 %>%
  filter(DEP %in% deps_paca)

cat("Nb points d'accueil PACA 2023 :", nrow(struct23_paca), "\n")

# --- Indicateurs de fragilité globaux ----------------------------------------
fragilite_paca <- struct23_paca %>%
  summarise(
    nb_points      = n(),
    nb_fermetures  = sum(STR_116_FERM == "1", na.rm = TRUE),
    pct_fermetures = round(nb_fermetures / nb_points * 100, 1),
    nb_regulation  = sum(STR_117_REGUL == "1", na.rm = TRUE),
    pct_regulation = round(nb_regulation / nb_points * 100, 1),
    nb_petits      = sum(NB_PASSAGES_4CL == "1.[0 - 40]", na.rm = TRUE),
    pct_petits     = round(nb_petits / nb_points * 100, 1),
    nb_grands      = sum(NB_PASSAGES_4CL == "4.[121 et +[", na.rm = TRUE),
    pct_grands     = round(nb_grands / nb_points * 100, 1)
  )

cat("\nIndicateurs de fragilité PACA :\n")
print(fragilite_paca)

cat("\n=== Comparaison PACA vs France (DREES ER1305) ===\n")
cat(sprintf("Fermetures     : PACA = %s%%  |  France = 8%%\n",  fragilite_paca$pct_fermetures))
cat(sprintf("Régulation     : PACA = %s%%  |  France = 23%%\n", fragilite_paca$pct_regulation))
cat(sprintf("Petits services: PACA = %s%%  |  France = 20%%\n", fragilite_paca$pct_petits))

# --- Fragilité par département -----------------------------------------------
fragilite_dep <- struct23_paca %>%
  group_by(DEP, LIBELLE_DEPARTEMENT) %>%
  summarise(
    nb_points      = n(),
    pct_fermetures = round(sum(STR_116_FERM == "1", na.rm = TRUE) / n() * 100, 1),
    pct_regulation = round(sum(STR_117_REGUL == "1", na.rm = TRUE) / n() * 100, 1),
    .groups        = "drop"
  ) %>%
  pivot_longer(
    cols      = c(pct_fermetures, pct_regulation),
    names_to  = "indicateur",
    values_to = "pct"
  ) %>%
  mutate(indicateur = recode(indicateur,
    "pct_fermetures" = "Fermetures temporaires",
    "pct_regulation" = "Régulation d'accès"
  ))

# --- Figure 4 : Fragilité par département ------------------------------------
fig4 <- ggplot(fragilite_dep,
               aes(x = reorder(LIBELLE_DEPARTEMENT, pct),
                   y = pct, fill = indicateur)) +
  geom_col(position = "dodge") +
  coord_flip() +
  scale_fill_manual(values = c(
    "Fermetures temporaires" = "#D62728",
    "Régulation d'accès"     = "#AEC6E8"
  )) +
  labs(
    title    = "Fragilité des urgences par département — PACA (2023)",
    subtitle = "% de points d'accueil concernés",
    x        = NULL,
    y        = "% de points d'accueil",
    fill     = NULL,
    caption  = "Source : DREES, Enquête Urgences 2023 — volet Structure"
  ) +
  theme_dadee() +
  theme(axis.text.x = element_text(angle = 0))

print(fig4)
ggsave("fig4_fragilite_dep.png", fig4, width = 9, height = 5, dpi = 150)
cat("Figure 4 sauvegardée : fig4_fragilite_dep.png\n")

# =============================================================================
# PARTIE 5 — MONTE CARLO (horizon 2025–2027, projection depuis 2023)
# =============================================================================

cat("\n=== Monte Carlo — Projections 2024–2027 ===\n")

set.seed(123)   # reproductibilité
N <- 10000      # nombre de simulations

# --- Calibration sur la tendance pré-COVID (2015–2019) -----------------------
# On exclut 2020 (choc exceptionnel) pour calibrer la dynamique structurelle
croissance_obs <- paca_agg %>%
  filter(an >= 2015, an <= 2019) %>%
  mutate(taux = (passages_total / lag(passages_total)) - 1) %>%
  filter(!is.na(taux)) %>%
  summarise(
    mu    = mean(taux),
    sigma = sd(taux)
  )

mu_g    <- croissance_obs$mu
sigma_g <- croissance_obs$sigma

cat(sprintf("Calibration : mu = %.2f%% | sigma = %.2f%%\n",
            mu_g * 100, sigma_g * 100))

# --- Simulation --------------------------------------------------------------
P0       <- paca_agg$passages_total[paca_agg$an == 2023]  # point de départ
annees   <- 2024:2027
n_annees <- length(annees)

# Matrice N × 4 : chaque ligne = une trajectoire simulée
simulations <- matrix(NA, nrow = N, ncol = n_annees)

for (i in 1:N) {
  P <- P0
  for (t in 1:n_annees) {
    g <- rnorm(1, mean = mu_g, sd = sigma_g)
    P <- P * (1 + g)
    simulations[i, t] <- P
  }
}

# --- Intervalles de confiance ------------------------------------------------
ic <- as_tibble(simulations) %>%
  setNames(as.character(annees)) %>%
  pivot_longer(everything(), names_to = "an", values_to = "passages") %>%
  mutate(an = as.integer(an)) %>%
  group_by(an) %>%
  summarise(
    median = median(passages),
    p10    = quantile(passages, 0.10),
    p25    = quantile(passages, 0.25),
    p75    = quantile(passages, 0.75),
    p90    = quantile(passages, 0.90),
    .groups = "drop"
  )

cat("\nTableau 3 — Projections Monte Carlo :\n")
print(ic %>% mutate(across(where(is.numeric), ~ round(., 0))))

# --- Figure 5 : Observé + projections Monte Carlo ----------------------------
obs <- paca_agg %>%
  select(an, passages_total) %>%
  mutate(type = "Observé")

proj_line <- ic %>%
  rename(passages_total = median) %>%
  mutate(type = "Projection (médiane)")

fig5 <- ggplot() +
  # Intervalle 10–90%
  geom_ribbon(data = ic,
              aes(x = an, ymin = p10, ymax = p90),
              fill = "#D62728", alpha = 0.12) +
  # Intervalle 25–75%
  geom_ribbon(data = ic,
              aes(x = an, ymin = p25, ymax = p75),
              fill = "#D62728", alpha = 0.25) +
  # Données observées
  geom_line(data  = obs,
            aes(x = an, y = passages_total, color = type),
            linewidth = 1.2) +
  geom_point(data = obs,
             aes(x = an, y = passages_total, color = type),
             size = 3) +
  # Projection médiane
  geom_line(data  = proj_line,
            aes(x = an, y = passages_total, color = type),
            linewidth = 1.2, linetype = "dashed") +
  geom_point(data = proj_line,
             aes(x = an, y = passages_total, color = type),
             size = 3) +
  # Séparation observé / projection
  geom_vline(xintercept = 2023.5, linetype = "dotted", color = "grey50") +
  annotate("text", x = 2024.1, y = min(obs$passages_total) * 0.985,
           label = "Projections \u2192", color = "grey50", size = 3.5, hjust = 0) +
  # Horizon de décision 2025-2027
  annotate("rect",
           xmin = 2024.5, xmax = 2027.5,
           ymin = -Inf,   ymax = Inf,
           fill = "steelblue", alpha = 0.05) +
  annotate("text", x = 2026, y = max(obs$passages_total) * 1.005,
           label = "Horizon décision\n2025–2027",
           color = "steelblue", size = 3, hjust = 0.5) +
  scale_color_manual(values = c(
    "Observé"              = "#2171B5",
    "Projection (médiane)" = "#D62728"
  )) +
  scale_x_continuous(breaks = 2015:2027) +
  scale_y_continuous(labels = label_number(suffix = "k", scale = 1e-3)) +
  labs(
    title    = "Passages aux urgences PACA — Observé et projeté (2015–2027)",
    subtitle = "Monte Carlo (N=10 000) — Intervalles 10–90% et 25–75% | Horizon décision : 2025–2027",
    x        = NULL,
    y        = "Passages (milliers)",
    color    = NULL,
    caption  = "Source : DREES, SAE CAPACT. Projections : Monte Carlo calibré sur tendance 2015–2019"
  ) +
  theme_dadee()

print(fig5)
ggsave("fig5_montecarlo.png", fig5, width = 10, height = 6, dpi = 150)
cat("Figure 5 sauvegardée : fig5_montecarlo.png\n")
