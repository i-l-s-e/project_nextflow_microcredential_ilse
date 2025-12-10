library(DBI)
library(duckdb)

args <- commandArgs(trailingOnly = TRUE)
dbfile <- args[1]
outfile <- args[2]

con <- dbConnect(duckdb::duckdb(), dbdir = dbfile)

# Simple SQL example
query <- "
SELECT
nct_id,
brief_title,
phase,
study_type,
CAST(enrollment AS INTEGER) as enrollment
FROM studies
WHERE phase IN ('Phase 2', 'Phase 3')
AND enrollment IS NOT NULL
"

result <- dbGetQuery(con, query)
write.csv(result, outfile, row.names = FALSE)

dbDisconnect(con)