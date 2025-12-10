
args <- commandArgs(trailingOnly=TRUE)
csvfile <- args[1]

csvfile <- "~/Nextflow/Nextflow_project/output/rawdata.csv"

df <- read.csv(csvfile, stringsAsFactors = FALSE)




# Coerce text Yes/No flags from various values
to_yesno <- function(x) {
  x <- tolower(as.character(x))
  case_when(
    str_detect(x, "random") ~ "Yes",
    str_detect(x, "yes|double|single|blinded|mask") ~ "Yes",
    str_detect(x, "no|open") ~ "No",
    TRUE ~ NA_character_
  )
}

# Numeric cleaning
to_numeric <- function(x) {
  suppressWarnings(as.numeric(gsub("[^0-9.+-]", "", x)))
}




# If structured extraction produced mostly NA, build regex fallback from JSON
need_regex <- sum(!is.na(death_struct$deaths_raw)) == 0

if (need_regex) {
  # Pull JSON strings (may be big)
  json_tbl <- DBI::dbGetQuery(con, "SELECT jsondata FROM studies")
  # For each JSON, capture the first integer appearing within ~40 chars after 'death'
  death_guess <- map_chr(tolower(json_tbl$jsondata), function(js) {
    m <- stringr::str_match(js, "(death\\w*\\D{0,40})(\\d{1,5})")
    if (!is.na(m[1,2])) m[1,3] else NA_character_
  })
  death_struct <- tibble(deaths_raw = death_guess)
}

# ---- 5) Bind all and normalize predictors ----

features <- bind_cols(
  eudract_df,
  phase_df,
  rand_df,
  blind_df,
  dis_df,
  age_low_df,
  age_up_df,
  n_df,
  fu_df,
  sae_df,
  death_struct
) %>%
  # Coerce types / tidy text
  mutate(
    trial_phase = if_else(is.na(trial_phase), NA_character_, as.character(trial_phase)),
    randomized  = to_yesno(randomization_raw),
    blinded     = case_when(
      str_detect(tolower(blinding_raw %||% ""), "double") ~ "Double",
      str_detect(tolower(blinding_raw %||% ""), "single") ~ "Single",
      str_detect(tolower(blinding_raw %||% ""), "open|none|no") ~ "Open",
      str_detect(tolower(blinding_raw %||% ""), "blind|mask") ~ "Blinded",
      TRUE ~ NA_character_
    ),
    age_lower_limit_years = to_numeric(age_lower_raw),
    age_upper_limit_years = to_numeric(age_upper_raw),
    sample_size_total     = to_numeric(sample_size_raw),
    follow_up_months      = to_numeric(follow_up_raw),
    serious_ae_count      = to_numeric(serious_ae_raw),
    deaths_count          = to_numeric(deaths_raw)
  ) %>%
  select(
    eudract_number,
    trial_phase,
    randomized,
    blinded,
    disease_area,
    age_lower_limit_years,
    age_upper_limit_years,
    sample_size_total,
    follow_up_months,
    serious_ae_count,
    deaths_count
  )

# ---- 6) Derive rates: serious AE % and all-cause mortality % ----

features <- features %>%
  mutate(
    serious_ae_rate_percent       = if_else(!is.na(serious_ae_count) & !is.na(sample_size_total) & sample_size_total > 0,
                                            round(100 * serious_ae_count / sample_size_total, 2), NA_real_),
    all_cause_mortality_percent   = if_else(!is.na(deaths_count) & !is.na(sample_size_total) & sample_size_total > 0,
                                            round(100 * deaths_count / sample_size_total, 2), NA_real_)
  ) %>%
  # Final column order: 10 predictors + target
  select(
    eudract_number,
    trial_phase,
    randomized,
    blinded,
    disease_area,
    age_lower_limit_years,
    age_upper_limit_years,
    sample_size_total,
    follow_up_months,
    serious_ae_rate_percent,
    all_cause_mortality_percent
  )
