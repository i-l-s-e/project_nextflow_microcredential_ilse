#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly=TRUE)
datadir <- args[1]


#install.packages("DBI")
#install.packages("duckdb")
library(DBI)
library(duckdb)


con<-DBI::dbConnect(duckdb::duckdb(,dbdir=paste0(datadir,"/clinicaltrials.duckdb")))
DBI::dbExecute(con,"INSTALL json;")
DBI::dbExecute(con,"LOAD 'json'")
DBI::dbDisconnect(con, shutdown=TRUE)


