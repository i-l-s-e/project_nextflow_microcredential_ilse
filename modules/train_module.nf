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