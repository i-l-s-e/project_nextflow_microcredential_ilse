process preprocess {

    publishDir params.outdir, mode: 'copy'
    container params.container
    
    input:
     path(csvfile)
     path(scriptsdir)
     

    output:
      path "prepared_data.csv", emit: prep_file

    script:
    """
     Rscript ${scriptsdir}/preprocess.R ${csvfile} .
    """
}