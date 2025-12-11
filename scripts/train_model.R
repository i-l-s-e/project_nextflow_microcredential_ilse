#!/usr/bin/env Rscript
# --- 02_train.R ---------------------------------------------------------------
# Purpose: Train a Poisson GLM (log link) with optional offset log(subjects_exposed_total)
#          and auto-switch to Negative Binomial if over-dispersion is detected.
#          Save the model to RDS.
library(dplyr)
library(MASS)      # glm.nb
library(readr)

args <- commandArgs(trailingOnly=TRUE)
infile <- args[1]
outdir <- args[2]


model_outfile <- paste0(outdir,"/model_deaths.rds")

# ---- 1) Load prepared data ----
dat <- read.csv(infile, check.names = FALSE)

# Target & offset
dat <- dat %>%
  mutate(
    deaths_total            = as.integer(deaths_total),
    subjects_exposed_total  = as.numeric(subjects_exposed_total)
  )

# Keep rows where we can fit the model
train <- dat %>%
  filter(!is.na(deaths_total),
         !is.na(subjects_exposed_total),
         subjects_exposed_total > 0)

# Categorical as factors
train <- train %>%
  mutate(
    therapeutic_area = as.factor(therapeutic_area)
  )

# ---- 2) Build formula (drop id/eudractNumber/condition_text/mortality_percent) ----
predictors <- c("randomised", "double_blind",
                "condition_is_diabetes",
                "therapeutic_area",
                "nonserious_ae_count")

f_base <- as.formula(paste("deaths_total ~", paste(predictors, collapse = " + ")))
f_glm  <- update(f_base, . ~ . + offset(log(subjects_exposed_total)))

# ---- 3) Fit Poisson ----
m_pois <- glm(f_glm, data = train, family = poisson(link = "log"))

# ---- 4) Check over-dispersion and refit NB if needed ----
overdisp_ratio <- m_pois$deviance / m_pois$df.residual
use_nb <- is.finite(overdisp_ratio) && (overdisp_ratio > 1.5)

if (use_nb) {
  message(sprintf("Over-dispersion detected (deviance/df = %.2f). Using Negative Binomial.", overdisp_ratio))
  model <- MASS::glm.nb(f_glm, data = train)
  model_type <- "neg_binom"
} else {
  message(sprintf("Poisson acceptable (deviance/df = %.2f).", overdisp_ratio))
  model <- m_pois
  model_type <- "poisson"
}

# ---- 5) Simple fit summary ----
cat("\nModel:", model_type, "\n")
print(summary(model))

# ---- 6) Save model + metadata ----
ml_out <- list(
  model     = model,
  modelType = model_type,
  predictors = predictors
)
saveRDS(ml_out, file = model_outfile)
message("Saved model: ", normalizePath(model_outfile))

