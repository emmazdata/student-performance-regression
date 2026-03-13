rm(list = ls())

# Packages
library(tidyverse)
library(broom)
library(lmtest)
library(performance)

# data import
data <- read_csv("project.csv", show_col_types = FALSE)

glimpse(data)
dim(data)


# missing values and duplicates 
colSums(is.na(data))
sum(duplicated(data))

#Encoding of qualitative variable
data <- data |>
  mutate(
    sexe = factor(sexe, levels = c(0, 1)),
    school_type = factor(school_type, levels = c(0, 1)),
    parent_educ = factor(parent_educ, levels = 1:6, ordered = TRUE),
    agecat = factor(agecat, levels = 1:5, ordered = TRUE),
    attend_pct_cat = factor(attend_pct_cat, levels = 1:4, ordered = TRUE),
    sleep_qual = factor(sleep_qual, levels = 1:5, ordered = TRUE),
    study_method = factor(study_method, levels = 1:6),
    web_access = factor(web_access, levels = c(0, 1)),
    extra_act = factor(extra_act, levels = c(0, 1)),
    trav_time = factor(trav_time, levels = 1:4)
  )

str(data)


# train/test 

set.seed(42)

n <- nrow(data)
test_size <- 1000
id_test <- sample(seq_len(n), size = test_size, replace = FALSE)

test <- data[id_test, ]
train <- data[-id_test, ]

dim(train)
dim(test)


## Baseline : moyenne de y
y_mean <- mean(train$y)
pred_baseline <- rep(y_mean, nrow(test))

mse_baseline <- mean((test$y - pred_baseline)^2)
medae_baseline <- median(abs(test$y - pred_baseline))
r2_baseline <- 1 - sum((test$y - pred_baseline)^2) / sum((test$y - mean(test$y))^2)

baseline_metrics <- data.frame(
  model = "baseline_mean",
  mse = mse_baseline,
  medAE = medae_baseline,
  r2 = r2_baseline
)

baseline_metrics

# EDA on the train
# Distribution of y
ggplot(train, aes(x = y)) +
  geom_histogram(aes(y = after_stat(density)),
                 bins = 30, fill = "grey80", color = "black") +
  geom_density(color = "blue", linewidth = 1) +
  labs(title = "Distribution of exam scores", x = "Exam score", y = "Density") +
  theme_bw(base_size = 14)

# Relation entre y et study_hrs
ggplot(train, aes(x = study_hrs, y = y)) +
  geom_point(alpha = 0.3, shape = 21, size = 2) +
  geom_smooth(method = "loess", se = FALSE) +
  labs(title = "Exam score vs Study hours", 
       x = "Study hours per week", 
       y = "Exam score") +
  theme_bw(base_size = 14)

# Relation entre y et attend_pct
ggplot(train, aes(x = attend_pct, y = y)) +
  geom_point(alpha = 0.3, shape = 21, size = 2) +
  geom_smooth(method = "loess", se = FALSE) +
  labs(title = "Exam score vs Attendance", 
       x = "Attendance percentage", 
       y = "Exam score") +
  theme_bw(base_size = 14)

# Relation entre y et sleep_hrs
ggplot(train, aes(x = sleep_hrs, y = y)) +
  geom_point(alpha = 0.3, shape = 21, size = 2) +
  geom_smooth(method = "loess", se = FALSE) +
  labs(title = "Exam score vs Sleep hours", 
       x = "Sleep hours per night", 
       y = "Exam score") +
  theme_bw(base_size = 14)

# Boxplots pour les variables catégorielles
ggplot(train, aes(x = parent_educ, y = y)) +
  geom_boxplot(fill = "grey80") +
  labs(title = "Exam score vs Parental education", 
       x = "Parental education level", 
       y = "Exam score") +
  theme_bw(base_size = 14)

ggplot(train, aes(x = study_method, y = y)) +
  geom_boxplot(fill = "grey80") +
  labs(title = "Exam score vs Study method", 
       x = "Study method", 
       y = "Exam score") +
  theme_bw(base_size = 14)

ggplot(train, aes(x = sleep_qual, y = y)) +
  geom_boxplot(fill = "grey80") +
  labs(title = "Exam score vs Sleep quality", 
       x = "Sleep quality", 
       y = "Exam score") +
  theme_bw(base_size = 14)

# 5. Models (only on the train)

m1 <- lm(y ~ study_hrs, data = train)
m2 <- lm(y ~ study_hrs + attend_pct + sleep_hrs, data = train)
m3 <- lm(y ~ study_hrs + attend_pct + sleep_hrs + parent_educ + study_method + sleep_qual, data = train)

summary(m1)
summary(m2)
summary(m3)

# Comparaison des modèles candidats 

# Critère 1: Critères de sélection (AIC, BIC, R² ajusté)
model_comparison <- compare_performance(
  m1, m2, m3,
  metrics = c("AIC", "BIC", "R2", "R2_adj", "SIGMA", "RMSE"),
  rank = TRUE
)

model_comparison

# Critère 2: Tests F pour modèles imbriqués (inférentiel)
anova(m1, m2)
anova(m2, m3)
anova(m1, m3)

# Résults of the final model: coefficients + IC 95%
coef_table_m3 <- tidy(m3, conf.int = TRUE, conf.level = 0.95)
coef_table_m3

# Performance (test)
pred_m1 <- predict(m1, newdata = test)
pred_m2 <- predict(m2, newdata = test)
pred_m3 <- predict(m3, newdata = test)

perf_metrics <- function(y_true, y_pred) {
  mse <- mean((y_true - y_pred)^2)
  medae <- median(abs(y_true - y_pred))
  r2 <- 1 - sum((y_true - y_pred)^2) / sum((y_true - mean(y_true))^2)
  c(mse = mse, medAE = medae, r2 = r2)
}

met_m1 <- perf_metrics(test$y, pred_m1)
met_m2 <- perf_metrics(test$y, pred_m2)
met_m3 <- perf_metrics(test$y, pred_m3)

test_metrics <- rbind(
  baseline_metrics,
  data.frame(model = "m1_simple", mse = met_m1["mse"], medAE = met_m1["medAE"], r2 = met_m1["r2"]),
  data.frame(model = "m2_core",   mse = met_m2["mse"], medAE = met_m2["medAE"], r2 = met_m2["r2"]),
  data.frame(model = "m3_final",  mse = met_m3["mse"], medAE = met_m3["medAE"], r2 = met_m3["r2"])
)

row.names(test_metrics) <- NULL
test_metrics


# Diagnostic du modèle final (m3) 

par(mfrow = c(2, 2))
plot(m3)
par(mfrow = c(1, 1))

# Breusch-Pagan (hétéroscédasticité)
bptest(m3)

# Cook's distance
cooks_d <- cooks.distance(m3)
plot(cooks_d, type = "h", main = "Cook's distance", ylab = "Cook's D")
abline(h = 4 / nrow(train), col = "red", lty = 2)

# Residus vs prédicteurs (model adequacy)
resid_df <- train |>
  mutate(
    resid = resid(m3),
    fitted = fitted(m3)
  )

# Résidus vs study_hrs
ggplot(resid_df, aes(x = study_hrs, y = resid)) +
  geom_point(shape = 21, size = 2, alpha = 0.5) +
  geom_hline(yintercept = 0, linetype = 2) +
  geom_smooth(method = "loess", se = FALSE) +
  labs(title = "Residuals vs Study hours", 
       x = "Study hours per week", 
       y = "Residuals") +
  theme_bw(base_size = 14)

# Résidus vs attend_pct
ggplot(resid_df, aes(x = attend_pct, y = resid)) +
  geom_point(shape = 21, size = 2, alpha = 0.5) +
  geom_hline(yintercept = 0, linetype = 2) +
  geom_smooth(method = "loess", se = FALSE) +
  labs(title = "Residuals vs Attendance percentage", 
       x = "Attendance percentage", 
       y = "Residuals") +
  theme_bw(base_size = 14)

# Résidus vs sleep_hrs
ggplot(resid_df, aes(x = sleep_hrs, y = resid)) +
  geom_point(shape = 21, size = 2, alpha = 0.5) +
  geom_hline(yintercept = 0, linetype = 2) +
  geom_smooth(method = "loess", se = FALSE) +
  labs(title = "Residuals vs Sleep hours", 
       x = "Sleep hours per night", 
       y = "Residuals") +
  theme_bw(base_size = 14)

# Résidus vs variables omises 
ggplot(resid_df, aes(x = age, y = resid)) +
  geom_point(shape = 21, size = 2, alpha = 0.5) +
  geom_hline(yintercept = 0, linetype = 2) +
  geom_smooth(method = "loess", se = FALSE) +
  labs(title = "Residuals vs Age (omitted variable)", 
       x = "Age", 
       y = "Residuals") +
  theme_bw(base_size = 14)

ggplot(resid_df, aes(x = trav_time, y = resid)) +
  geom_boxplot(fill = "grey80") +
  labs(title = "Residuals vs Travel time (omitted variable)", 
       x = "Travel time", 
       y = "Residuals") +
  theme_bw(base_size = 14)

ggplot(resid_df, aes(x = sexe, y = resid)) +
  geom_boxplot(fill = "grey80") +
  labs(title = "Residuals vs Gender (omitted variable)", 
       x = "Gender", 
       y = "Residuals") +
  theme_bw(base_size = 14)


# Calibration plot (test)
cal_df <- data.frame(y_true = test$y, y_pred = pred_m3)

# Graphique de calibration
ggplot(cal_df, aes(x = y_pred, y = y_true)) +
  geom_point(alpha = 0.3, shape = 21, size = 2) +
  geom_smooth(method = "loess", se = FALSE, color = "blue") +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed", color = "red") +
  labs(title = "Calibration plot (test set)",
       x = "Predicted exam score",
       y = "Observed exam score") +
  theme_bw(base_size = 14)


# Scénarios : profils réalistes + scores prédits (IC de confiance)
profiles <- data.frame(
  study_hrs = c(4, 8, 12),
  attend_pct = c(60, 80, 95),
  sleep_hrs = c(6, 7.5, 8),
  parent_educ = factor(c(2, 4, 6), levels = levels(train$parent_educ), ordered = TRUE),
  study_method = factor(c(3, 1, 6), levels = levels(train$study_method)),
  sleep_qual = factor(c(1, 2, 3), levels = levels(train$sleep_qual), ordered = TRUE)
)

profiles

# Prédictions avec IC 95%
pred_profiles <- predict(m3, newdata = profiles, interval = "confidence", level = 0.95)
profiles_pred <- cbind(profiles, pred_profiles)

profiles_pred
