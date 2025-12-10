# Fetch a small subset of clinical trial records using rctapi
# Install if needed
install.packages("ctrdata")
install.packages("dplyr")
install.packages("tidyr")
install.packages("readr")
install.packages("nodbi")
install.packages("duckdb")

# Load libraries
library(ctrdata)
library(dplyr)
library(nodbi)
library(readr)
library(duckdb)

# Use a temporary local database
duckfile="~/Nextflow/Nextflow_project/data/clinicaltrials.duckdb"
db <- nodbi::src_duckdb(
        dbdir = duckfile,
        collection = "studies")

queries <- ctrGenerateQueries(
        condition = "diabetes"
)

queries <- ctrGenerateQueries(
        condition="diabetes",
        phase="phase 3",
        recruitment ="completed",
        onlyMedIntervTrials = TRUE)

# load data into DuckDB
lapply(
    queries[[1]],
    ctrLoadQueryIntoDb,
    con=db,
    euctrresults =TRUE,
    euctrprotocolsall = FALSE)


# Disconnect from the database

dbDisconnect(db$con, shutdown = TRUE)
