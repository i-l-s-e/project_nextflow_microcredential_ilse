library(DBI)
library(duckdb)


args <- commandArgs(trailingOnly=TRUE)
studyfile <- args[1]
dbfile <- args[2]

# Connect to DuckDB
con <- dbConnect(duckdb(dbfile), read_only=TRUE)


# Install and load JSON extension
DBI::dbExecute(con, "INSTALL json;")
DBI::dbExecute(con, "LOAD json;")

# Example flattening
df <- dbGetQuery(con, "
    SELECT
        json_extract_string(trialInformation, '$.a11') AS title,
        json_extract_string(trialInformation, '$.e11_medical_conditions_being_investigated') AS condition,
        json_extract_string(trialInformation, '$.e73_therapeutic_confirmatory_phase_iii') AS phase3,
        *
    FROM trialInformation
")

#plug in the code from work PC



# Load CSV into DuckDB
df <- read.csv(studyfile)
dbWriteTable(db, "studies", df, overwrite = TRUE)

dbDisconnect(db)







# helpers to define paths in JSON data
# ---- 2) Small helpers to find & extract fields from JSON ----

# Find candidate field paths for one or more keywords
find_paths <- function(keywords, limit = 30) {
  res_list <- lapply(keywords, function(k) {
    ctrdata::dbFindFields(con = db, namepart = k)
  })
  res <- do.call(rbind, res_list)
  if (is.null(res) || nrow(res) == 0) return(character(0))

  # take up to 'limit' names per keyword set, keep unique
  res<-as.vector(unlist(res,use.names=FALSE))
  names(res)<-NULL
  unique(res[seq_len(min(length(res), limit))])
}
# Pick the best field among candidates (greatest non-NA coverage),
# and return a one-column tibble with the desired label.
extract_first_good <- function(paths, label) {
  if (length(paths) == 0) return(tibble::tibble(!!label := NA_character_))

  dfs <- lapply(paths, function(p) {
    # dbGetFieldsIntoDf expects a vector of field names
    tryCatch(ctrdata::dbGetFieldsIntoDf(con = db, fields = p),
             error = function(e) NULL)
  })
  dfs <- Filter(Negate(is.null), dfs)
  if (length(dfs) == 0) return(tibble::tibble(!!label := NA_character_))

  coverage <- vapply(dfs, function(x) sum(!is.na(x[[1]])), numeric(1))
  best <- dfs[[which.max(coverage)[1]]]
  print(names(dfs))
  print(names(best))
  best<-setNames(best, c("ID",label))
  tibble::tibble(best)
}





# EudraCT number (top-level, usually stable)
eudract_paths <- find_paths(c("eudractNumber", "eudract"))
eudract_df    <- extract_first_good(eudract_paths, "eudract_number")

# Trial phase
phase_paths   <- find_paths(c("phase", "trialPhase"))
phase_df      <- extract_first_good(phase_paths, "trial_phase")

# Randomization
rand_paths    <- find_paths(c("random", "allocation"))
rand_df       <- extract_first_good(rand_paths, "randomization_raw")

# Blinding / masking
blind_paths   <- find_paths(c("blind", "mask"))
blind_df      <- extract_first_good(blind_paths, "blinding_raw")

# Disease area / indication
dis_paths     <- find_paths(c("therapeutic", "indication", "condition", "disease"))
dis_df        <- extract_first_good(dis_paths, "disease_area")

# Age limits
age_low_paths <- find_paths(c("age"))
age_up_paths  <- find_paths(c("age", "upper", "max"))
age_low_df    <- extract_first_good(age_low_paths, "age_lower_raw")
age_up_df     <- extract_first_good(age_up_paths,  "age_upper_raw")

# Sample size (participants/enrolled/randomized)
n_paths       <- find_paths(c("subjectsExposed"))
n_df          <- extract_first_good(n_paths, "sample_size_raw")

# Follow-up duration (months preferred)
fu_paths      <- find_paths(c("follow-up", "duration", "time", "months"))
fu_df         <- extract_first_good(fu_paths, "follow_up_raw")

# Serious AEs (counts) - if available
sae_paths     <- find_paths(c("serious adverse", "SAE", "serious"))
sae_df        <- extract_first_good(sae_paths, "serious_ae_raw")

# ---- 4) Death counts: structured first; fallback to regex from JSON ----

death_paths   <- find_paths(c("death", "deaths", "fatal", "mortality"))
death_struct  <- extract_first_good(death_paths, "deaths_raw")








sum_affected_from_values <- function(x) {
  if (is.na(x) || !nzchar(x)) return(NA_integer_)
  # Split and trim commas/spaces
  parts <- strsplit(x, ",")[[1]]
  parts <- trimws(parts)
  
  total_len <- length(parts)
  
  if (total_len %% 4 != 0) {
    warning("values string length is not divisible by 4. String: ", x)
    return(NA_integer_)
  }
  
  N <- total_len / 4  # number of groups
  
  # affected section = elements from (2N+1) to (3N)
  affected_idx <- (2*N + 1):(3*N)
  
  affected_vals <- suppressWarnings(as.numeric(parts[affected_idx]))
  
  if (any(is.na(affected_vals))) {
    warning("non-numeric affected values in: ", x)
    return(NA_integer_)
  }
  
  sum(affected_vals)
}


library(stringr)
library(purrr)

sum_affected_from_values_vec <- function(xvec) {
  if (is.null(xvec) || length(xvec) == 0) return(NA_real_)
  
  # Apply the parser to each element of the vector
  vals_each <- map_dbl(xvec, function(x) {
    if (is.na(x) || !nzchar(x)) return(0)

    parts <- str_split(x, ",\\s*")[[1]]
    suppressWarnings(nums <- as.numeric(parts))
    nums <- nums[!is.na(nums)]

    if (length(nums) == 0) return(0)

    # Three numeric blocks per group:
    # 1) occurrences
    # 2) affected  <-- we want this
    # 3) total subjects
    n_groups <- length(nums) / 3
    if (n_groups %% 1 != 0) return(0)

    idx_start <- n_groups + 1
    idx_end   <- n_groups * 2

    sum(nums[idx_start:idx_end])
  })

  # Sum all strings' "affected" totals  
  sum(vals_each, na.rm = TRUE)
}



sum_affected_from_nested_tbl <- function(tbl) {
  if (is.null(tbl)) return(NA_real_)
  if (!("subjectsAffected" %in% names(tbl[[1]]))) return(NA_real_)

  sum(as.numeric(tbl[[1]][["subjectsAffected"]]), na.rm = TRUE)
}
