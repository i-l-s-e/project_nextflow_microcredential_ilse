#!/usr/bin/env Rscript 

args <- commandArgs(trailingOnly=TRUE)
out_file <- args[1]
outdir <- args[3]

outfile <- paste0(outdir,"/results.txt")

out <- read.csv(out_file, check.names = FALSE)



if (!is.numeric(out$predicted_deaths)) {
  stop("Column 'predicted_deaths' must be numeric.")
}

# Summary statistics
n_records   <- nrow(out)
mean_pred   <- mean(out$predicted_deaths, na.rm = TRUE)
median_pred <- median(out$predicted_deaths, na.rm = TRUE)
min_pred    <- min(out$predicted_deaths, na.rm = TRUE)
max_pred    <- max(out$predicted_deaths, na.rm = TRUE)
timestamp   <- format(Sys.time(), "%Y-%m-%d %H:%M %Z")

# Helper: format numbers with thousands separator using base R
fmt <- function(x) {
  if (is.na(x)) return("NA")
  format(x, big.mark = ",", scientific = FALSE, trim = TRUE)
}



# ---------------------------------------------------------
# Construct a Markdown pipe table in base R (no kable)
# ---------------------------------------------------------
# Columns to include (adjust if needed)
cols <- c("id", "eudractNumber", "predicted_deaths")

# Header row
md_header_row <- paste(cols, collapse = " | ")
md_sep_row    <- paste(rep("---", length(cols)), collapse = " | ")

# Data rows (coerce to character, preserve NA)
row_to_md <- function(i) {
  vals <- out[i, cols, drop = TRUE]
  vals <- vapply(vals, function(x) {
    if (is.na(x)) "NA" else as.character(x)
  }, FUN.VALUE = character(1))
  paste(vals, collapse = " | ")
}
md_data_rows <- vapply(seq_len(nrow(out)), row_to_md, FUN.VALUE = character(1))

md_table_block <- c(
  paste0("| ", md_header_row, " |"),
  paste0("| ", md_sep_row, " |"),
  paste0("| ", md_data_rows, " |")
)

# ---------------------------------------------------------
# Build Markdown content
# ---------------------------------------------------------
md_lines <- c(
  "# Prediction Results",
  "",
  paste0("Generated on **", timestamp, "**"),
  "",
  paste0(
    "This report summarizes the output of a prediction model applied to ",
    fmt(n_records), " records. Key distribution metrics of `predicted_deaths` ",
    "are provided, followed by a compact preview of the first 10 rows."
  ),
  "",
  "## Summary",
  paste0("- Total records: **", fmt(n_records), "**"),
  paste0("- Mean predicted deaths: **", fmt(mean_pred), "**"),
  paste0("- Median predicted deaths: **", fmt(median_pred), "**"),
  paste0("- Range (min–max): **", fmt(min_pred), "–", fmt(max_pred), "**"),
  "",
  "## Top 10 preview",
  md_table_block
)

# Write Markdown
writeLines(md_lines, con = "prediction_results.md")

# ---------------------------------------------------------
# Build Text content (plain .txt)
# ---------------------------------------------------------
# For the preview, use base print() capture

txt_lines <- c(
  "Prediction Results",
  sprintf("Generated on %s", timestamp),
  "",
  sprintf("Total records: %s", fmt(n_records)),
  sprintf("Mean predicted deaths: %s", fmt(mean_pred)),
  sprintf("Median predicted deaths: %s", fmt(median_pred)),
  sprintf("Range (min–max): %s–%s", fmt(min_pred), fmt(max_pred)),
  ""
)

# Write Text
writeLines(txt_lines, con = "prediction_results.txt")
