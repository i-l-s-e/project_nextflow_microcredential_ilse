process preprocess {

    publishDir params.outdir, mode: 'copy'
    container params.container
    
    input:
     path(csvfile)

     

    output:
      path "prepared_data.csv", emit: prep_file

    script:
    """
     Rscript ${params.scriptsdir}/preprocess.R ${csvfile} .
    """
}