#!/usr/bin/env Rscript 
#--- 01_preprocess.R ----------------------------------------------------------
# Purpose: Read rawdata.csv, flatten "x / y / z" counts, engineer features,
#          and save prepared_data.csv for modeling.
# ---- Libraries ----
library(dplyr)
library(stringr)
library(readr)

# ---- inputs ----
args <- commandArgs(trailingOnly=TRUE)
infile <- args[1]
outdir <- args[2]

outfile <- paste0(outdir,"/prepared_data.csv")

# ---- Helpers ----
# Sum all numbers found in a string like "183 / 177 / 179" -> 539
parse_sum_vec <- function(x) {
  sapply(x, function(s) {
    if (is.na(s) || nchar(s) == 0) return(NA_real_)
    nums <- str_extract_all(s, "[0-9]+\\.?[0-9]*")[[1]]
    if (length(nums) == 0) return(NA_real_)
    sum(as.numeric(nums))
  })
}

# ---- 1) Load ----
df_raw <- read.csv(infile, check.names = FALSE, na.strings = c("NA", ""))

# Standardize some column names to simpler ones
df <- df_raw %>%
  rename(
    id                  = `_id`,
    eudractNumber       = `eudractNumber`,
    randomised          = `e811_randomised`,
    double_blind        = `e814_double_blind`,
    therapeutic_area    = `e112_therapeutic_area`,
    condition_text      = `e11_medical_conditions_being_investigated`,
    subjectsExposed_raw = `adverseEvents.reportingGroups.reportingGroup.subjectsExposed`,
    nonSeriousAE_raw    = `adverseEvents.nonSeriousAdverseEvents.nonSeriousAdverseEvent`,
    deaths_raw          = `adverseEvents.reportingGroups.reportingGroup.deathsAllCauses`
  )

# ---- 2) Flatten multi-arm counts & parse numerics ----
df <- df %>%
  mutate(
    subjects_exposed_total = parse_sum_vec(subjectsExposed_raw),
    deaths_total            = parse_sum_vec(deaths_raw),
    nonserious_ae_count     = readr::parse_number(as.character(nonSeriousAE_raw))
  )

# ---- 3) Basic feature engineering ----
df <- df %>%
  mutate(
    randomised    = as.integer(randomised),       # TRUE/FALSE -> 1/0 (NA stays NA)
    double_blind  = as.integer(double_blind),
    therapeutic_area = if_else(is.na(therapeutic_area) | therapeutic_area == "",
                               "Unknown", therapeutic_area),
    # simple flag: is the study about diabetes? (captures most variants)
    condition_is_diabetes = as.integer(
      str_detect(tolower(coalesce(as.character(condition_text), "")), "diabet")),
    # optional derived rate (not used as target, but can be a predictor)
    mortality_percent = if_else(!is.na(deaths_total) & !is.na(subjects_exposed_total) & subjects_exposed_total > 0,
                                100 * deaths_total / subjects_exposed_total, NA_real_)
  )

# ---- 4) Keep columns useful for modeling & write ----
prepared <- df %>%
  select(
    id, eudractNumber,
    randomised, double_blind,
    therapeutic_area, condition_is_diabetes,
    subjects_exposed_total, nonserious_ae_count,
    deaths_total, mortality_percent,
    condition_text
  )

# (Optional) drop rows without a target (deaths_total)
# prepared <- prepared %>% filter(!is.na(deaths_total))

write.csv(prepared, outfile, row.names = FALSE)
message("Saved: ", normalizePath(outfile))
