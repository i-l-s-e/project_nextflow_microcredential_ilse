#!/usr/bin/env Rscript 
# --- 03_predict.R -------------------------------------------------------------
# Purpose: Load the trained model, (re)apply the same parsing to new data,
#          and print id + eudractNumber + predicted deaths to the console.
library(dplyr)
library(stringr)
library(readr)

args <- commandArgs(trailingOnly=TRUE)
data_infile <- args[1]
model_infile<- args[2]
outdir <- args[3]

outfile <- paste0(outdir,"/results.csv")

# ---- Helpers (same as in preprocess, in case you score a raw file) ----
parse_sum_vec <- function(x) {
  sapply(x, function(s) {
    if (is.na(s) || nchar(s) == 0) return(NA_real_)
    nums <- str_extract_all(s, "[0-9]+\\.?[0-9]*")[[1]]
    if (length(nums) == 0) return(NA_real_)
    sum(as.numeric(nums))
  })
}

# ---- 1) Load model ----
ml_out <- readRDS(model_infile)
model      <- ml_out$model
predictors <- ml_out$predictors

# ---- 2) Load data to score ----
newdat <- read.csv(data_infile, check.names = FALSE)

# Ensure required fields exist and correct types
newdat <- newdat %>%
  mutate(
    randomised             = as.integer(randomised),
    double_blind           = as.integer(double_blind),
    condition_is_diabetes  = as.integer(condition_is_diabetes),
    nonserious_ae_count    = as.numeric(nonserious_ae_count),
    subjects_exposed_total = as.numeric(subjects_exposed_total),
    therapeutic_area       = as.factor(if_else(is.na(therapeutic_area) | therapeutic_area == "", "Unknown", therapeutic_area))
  )

# Keep rows we can score (need non-missing offset)
score_dat <- newdat %>%
  filter(!is.na(subjects_exposed_total),
         subjects_exposed_total > 0)

# ---- 3) Predict expected deaths (type='response') ----
pred <- predict(model, newdata = score_dat, type = "response")
pred <- pmax(pred, 0)  # safety clamp

out <- tibble::tibble(
  id            = score_dat$id,
  eudractNumber = score_dat$eudractNumber,
  predicted_deaths = as.numeric(pred)
)

# ---- 4) Print a compact view (top 10) ----
print(out, n = min(nrow(out), 10))

write.csv(out, outfile, row.names = FALSE)
message("Saved: ", normalizePath(outfile))