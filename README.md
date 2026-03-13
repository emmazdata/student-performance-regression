# 📊 Student Performance Analysis — Multiple Linear Regression in R

> Academic project · M1 MIDO, 2025–2026 · Linear Models Course

[![R](https://img.shields.io/badge/R-4.x-276DC3?logo=r&logoColor=white)](https://www.r-project.org/)
[![Quarto](https://img.shields.io/badge/Quarto-Report-4A90D9?logo=quarto)](https://quarto.org/)
[![Status](https://img.shields.io/badge/Status-Complete-success)](.)

---

## 📌 Overview

This project investigates the factors that influence student exam performance using a dataset of **5,000 students**. The analysis covers exploratory data analysis, multiple linear regression modelling, model diagnostics, and out-of-sample predictive evaluation.

The dataset includes variables spanning individual characteristics (age, gender), learning environment (school type, internet access), study habits (study hours, study method), and health-related factors (sleep hours, sleep quality).

**Response variable:** `y` — exam score (continuous)

---

## 🎯 Objectives

- Identify key predictors of exam performance via EDA and regression modelling
- Build a **parsimonious and interpretable** multiple linear regression model
- Rigorously check model assumptions (linearity, homoskedasticity, normality, influence)
- Evaluate **out-of-sample predictive performance** (MSE, R², MedAE, calibration)
- Provide scenario-based predictions for realistic student profiles

---

## 🗂️ Repository Structure

```
student-performance-regression/
│
├── project.csv          # Raw dataset (5 000 students, 16 variables)
├── report.qmd           # Quarto source — fully reproducible report
├── report.html          # Rendered HTML report (read directly in browser)
│
└── R/
    └── run_analysis.R   # End-to-end analysis script (runs from clean session)
```

---

## 📐 Methods

### Data Preparation
- Conversion of coded integers to labelled factors with appropriate reference categories
- Ordered factors for naturally ordinal variables (`parent_educ`, `sleep_qual`, `attend_pct_cat`, `agecat`)
- Data integrity checks: no missing values, no duplicate rows detected
- Decision on duplicate representations (continuous vs. categorical): `attend_pct` retained over `attend_pct_cat` to preserve granularity; `age` dropped in favour of the continuous version

### Modelling Strategy
Three candidate models were built and compared:

| Model | Predictors | Adjusted R² | AIC |
|-------|-----------|-------------|-----|
| M1 — Simple | `study_hrs` | — | — |
| M2 — Core | `study_hrs`, `attend_pct`, `sleep_hrs` | — | — |
| **M3 — Final** | `study_hrs`, `attend_pct`, `sleep_hrs`, `parent_educ`, `study_method`, `sleep_qual` | — | — |

> 📄 See the rendered report for the full comparison table with all metrics.

Models were compared using:
1. **Inferential criterion** — nested F-tests (ANOVA)
2. **Selection criteria** — AIC, BIC, adjusted R²

### Validation Protocol
- **Train/test split**: 4 000 train / 1 000 test — `set.seed(42)`
- No data leakage: all preprocessing learned on training data only
- Baseline model: predicting the training mean of `y`

---

## 📊 Key Results

### Predictors in the Final Model (M3)
The following variables were retained in the final model:

- **`study_hrs`** — weekly study hours (positive association)
- **`attend_pct`** — school attendance percentage (positive association)
- **`sleep_hrs`** — nightly sleep duration
- **`parent_educ`** — parental education level (ordered factor)
- **`study_method`** — study method used (6 categories)
- **`sleep_qual`** — sleep quality (ordered: Poor / Average / Good)

### Predictive Performance (test set, n = 1 000)

| Model | MSE | MedAE | R² (test) |
|-------|-----|-------|-----------|
| Baseline (train mean) | — | — | ~0 |
| M1 — Simple | — | — | — |
| M2 — Core | — | — | — |
| **M3 — Final** | — | — | — |

> 📄 Full metrics available in the rendered HTML report.

### Diagnostics
- Residuals vs. fitted: assessed for linearity and homoskedasticity
- Q–Q plot: checked normality of residuals
- Cook's distance: influential observations identified and discussed
- Breusch–Pagan test: formal heteroskedasticity check
- Residuals vs. omitted variables (`age`, `trav_time`, `sexe`): no systematic patterns detected

---

## 📁 How to Reproduce

### Requirements

```r
install.packages(c("tidyverse", "broom", "lmtest", "performance"))
```

### Run the full analysis

```r
# From the project root directory:
source("R/run_analysis.R")
```

### Render the Quarto report

```r
quarto::quarto_render("report.qmd")
```

Or from the terminal:
```bash
quarto render report.qmd
```

> ⚠️ Use **relative paths only** — the project must run from a fresh R session without interactive steps.

---

## 🛠️ Tools & Packages

| Tool | Purpose |
|------|---------|
| R 4.x | Statistical computing |
| `tidyverse` | Data wrangling & visualisation |
| `broom` | Tidy model outputs |
| `lmtest` | Heteroskedasticity tests (Breusch–Pagan) |
| `performance` | Model comparison (AIC, BIC, R²) |
| Quarto | Reproducible report rendering |

---

## 👩‍💻 Authors

**Hanna Malet & Emma Zouari** — M1 MIDO, 2025–2026

---

## 📝 Note

This is an academic project. The dataset is observational — all estimated effects should be interpreted as **associations**, not causal relationships.
