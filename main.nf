nextflow.enable.dsl=2


params.outdir = "output"



workflow {
download_data()
//init_db(fetch_data.out)
//run_query(init_db.out)
//train_model(run_query.out)
}


process download_data {
    tag "download_data"
    //make sure the output data is copied to the output folder
    publishDir params.outdir, mode: 'copy'
    container params.container
    conda params.conda
    cpus 2
    memory '2 GB'

    output:
    path "clinicaltrials.duckdb" into db_file

    script:
    """
    Rscript scripts/install.R
    Rscript scripts/fetch_data.R clinicaltrials.duckdb
    """
}


process convert_data {
    input:
    file db from db_file

    output:
    file "clean_trials.csv"

    script:
    """
    Rscript convert_to_csv.R ctrdata.duckdb
    """
}


process run_query {
input:
file "clinical.duckdb"
output:
file "query_output.csv"

script:
"""
Rscript scripts/run_query.R clinical.duckdb query_output.csv
"""
}

process train_model {
input:
file "query_output.csv"
output:
file "model.rds"

script:
"""
Rscript scripts/train_model.R query_output.csv model.rds
"""
}