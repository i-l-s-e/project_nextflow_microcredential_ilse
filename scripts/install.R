con<-DBI::dbConnect(duckdb::duckdb(,dbdir="~/Nextflow/Nextflow_project/data/clinicaltrials.duckdb"))
DBI::dbExecute(con,"INSTALL json;")
DBI::dbExecute(con,"LOAD 'json'")
DBI::dbDisconnect(con, shutdown=TRUE)
