
process install{
    publishDir params.outdir, mode: 'copy'
    container params.container
    
    input:
    path(scriptsdir)
  
    output:
    path "clinicaltrials.duckdb", emit: db_file
   

    script:
    """
    Rscript ${scriptsdir}/install.R  .
    """
}


process download_data {
    tag "download_data"
    //make sure the output data is copied to the output folder
    publishDir params.outdir, mode: 'copy'
    container params.container
    
    input:
    path(db_file)
    path(scriptsdir)
   
   

    output:
    path "clinicaltrials.duckdb", emit: db_file
    

    script:
    """
    Rscript ${scriptsdir}/fetch_data.R ${db_file}  .
    """
}


process convert_data {

    publishDir params.outdir, mode: 'copy'
    container params.container
    
    input:
     path(db_file)
     path(scriptsdir)
     
    

    output:
      path "rawdata.csv", emit: raw_file
    

    script:
    """
     Rscript ${scriptsdir}/init_db.R ${db_file} .
    """
}
