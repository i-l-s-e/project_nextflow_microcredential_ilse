#!/usr/bin/env Rscript
# -------------------------------
#  converting data from duckdb
# -------------------------------
# Packages
library(ctrdata)     
library(nodbi)       
library(DBI)         
library(dplyr)       
library(stringr)     
library(jsonlite)    
library(purrr)       
library(tidyr)       

# ---- 1) Connect to your DuckDB file ----
# Use a temporary local database
args <- commandArgs(trailingOnly=TRUE)
db_file <- args[1]
outdir <- args[2]

duckfile<-db_file

db <- nodbi::src_duckdb(
  dbdir = duckfile, 
  collection = "studies")  


fields<-c(
    "eudractNumber",
    "e811_randomised",
    "e814_double_blind",
    "e112_therapeutic_area",
    "e11_medical_conditions_being_investigated",
    "adverseEvents.reportingGroups.reportingGroup.subjectsExposed",
    "adverseEvents.nonSeriousAdverseEvents.nonSeriousAdverseEvent",
    "adverseEvents.reportingGroups.reportingGroup.deathsAllCauses"
)

#---helper code
sum_affected_from_nested_tbl <- function(tbl) {
  if (is.null(tbl)) return(NA_real_)
  if (!("subjectsAffected" %in% names(tbl[[1]]))) return(NA_real_)

  sum(as.numeric(tbl[[1]][["subjectsAffected"]]), na.rm = TRUE)
}






# ---- collect the data ----
dfs <- lapply(fields, function(p) {
    tryCatch(ctrdata::dbGetFieldsIntoDf(con = db, fields = p),
             error = function(e) NULL)
  })
  dfs <- Filter(Negate(is.null), dfs)
# special care for thenumber of subjects with AEs, this is in a nested structure 
colnames_list <- map(dfs[[7]][[2]], names)
has_values <- map_lgl(colnames_list, ~ "values" %in% .x)
tibbles_with_values <- dfs[[7]][[2]][has_values]
flattened <- map(tibbles_with_values, function(tb) {
  vals<-tb$values
  if   ("subjectsAffected" %in% names(vals[[1]]))   {
   
      affected_sum = sum(as.numeric(vals[[1]]["subjectsAffected"][[1]]))
    
  } else {
      affected_sum = as.numeric(map_dbl(vals, ~ sum_affected_from_nested_tbl(.x)))
    
  } 
})
dfs[[7]][[2]] <- map_dbl(flattened, ~ .x)
features <- reduce(dfs,full_join, by="_id")


# ---- 7) Save to CSV ----
outfile <- paste0(outdir,"/rawdata.csv")
write.csv(features, outfile, row.names = FALSE)
message("Saved: ", normalizePath(outfile))



