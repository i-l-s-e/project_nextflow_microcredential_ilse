#!/usr/bin/env Rscript
# Fetch a small subset of clinical trial records using rctapi
# Instalation should be covered by container
# install.packages("ctrdata")
# install.packages("dplyr")
# install.packages("tidyr")
# install.packages("readr")
# install.packages("nodbi")
# install.packages("duckdb")

# Load libraries
library(ctrdata)
library(dplyr)
library(nodbi)
library(readr)
library(duckdb)    
library(DBI)                
library(stringr)     
library(jsonlite)    
library(purrr)       
library(tidyr)    




# Use a temporary local database
args <- commandArgs(trailingOnly=TRUE)
db_file <- args[1]
outdir<-args[2]
condition <- args[3]
#duckfile<-paste0(outdir,"/clinicaltrials.duckdb")
duckfile<-db_file



#duckfile=db_file
db <- nodbi::src_duckdb(
        dbdir = duckfile,
        collection = "studies")


queries <- ctrGenerateQueries(
        condition=condition,
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
