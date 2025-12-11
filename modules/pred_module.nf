process predict {
  publishDir params.outdir, mode: 'copy'
  container params.container
  input:
  path(csvfile2)
  path(model_file)


  output:
  path "results.csv", emit: res_file

  script:
  """
  Rscript ${params.scriptsdir}/predict.R ${csvfile2} ${model_file} .
  """
}