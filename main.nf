nextflow.enable.dsl=2


params.outdir = "${projectDir}/output"
params.scriptsdir = "${projectDir}/scripts/"
params.datadir = "${projectDir}/data/"
//params.container = "${projectDir}/scripts/rbase-v02.sif"
//params.container = 'ilseclvd/rcontainer/v0.2'
params.container= 'community.wave.seqera.io/library/r-ctrdata_r-dbi_r-dplyr_r-duckdb_pruned:7bf0df866893c97c'


workflow {
//def datadir = channel.fromPath(params.datadir)
def scriptdir = channel.fromPath(params.scriptsdir)
def outdir = channel.fromPath(params.outdir)


install(scriptdir)
download_data(install.out.db_file,scriptdir)
convert_data(download_data.out.db_file,scriptdir)
preprocess(convert_data.out.raw_file,scriptdir)
train_model(preprocess.out.prep_file,scriptdir)
predict(preprocess.out.prep_file,train_model.out.model_file,scriptdir)
write(predict.out.res_file,scriptdir)
}

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

process train_model {
  publishDir params.outdir, mode: 'copy'
  container params.container
  input:
  path(csvfile2)
  path(scriptsdir)

  output:
  path "model_deaths.rds", emit: model_file

  script:
  """
  Rscript ${scriptsdir}/train_model.R ${csvfile2} .
  """
}
process predict {
  publishDir params.outdir, mode: 'copy'
  container params.container
  input:
  path(csvfile2)
  path(model_file)
  path(scriptsdir)

  output:
  path "results.csv", emit: res_file

  script:
  """
  Rscript ${scriptsdir}/predict.R ${csvfile2} ${model_file} .
  """
}


process write {
  publishDir params.outdir, mode: 'copy'
  container params.container
  input:
  path(out_file)
  path(scriptsdir)



  script:
  """
  Rscript ${scriptsdir}/write.R ${out_file}  .
  """
}