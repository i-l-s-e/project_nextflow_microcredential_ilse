
process install{
    publishDir params.outdir, mode: 'copy'
    container params.container
    

  
    output:
    path "clinicaltrials.duckdb", emit: db_file
   

    script:
    """
    Rscript ${params.scriptsdir}/install.R  .
    """
}


process download_data {
    tag "download_data"
    //make sure the output data is copied to the output folder
    publishDir params.outdir, mode: 'copy'
    container params.container
    
    input:
    path(db_file)
    val cond

   
   

    output:
    path "clinicaltrials.duckdb", emit: db_file
    

    script:
    """
    Rscript ${params.scriptsdir}/fetch_data.R ${db_file}  . ${cond}
    """
}


process convert_data {

    label 'R'
    publishDir params.outdir, mode: 'copy'

    input:
     path(db_file)
     val (split)
     
    

    output:
      path "rawdata.csv", emit: raw_file
      path "rawdata_val.csv", emit: raw_val_file

    script:
    """
     Rscript ${params.scriptsdir}/init_db.R ${db_file} . ${split}
    """
}
