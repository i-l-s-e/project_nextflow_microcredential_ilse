nextflow.enable.dsl=2


params.outdir = "${projectDir}/output"
params.scriptsdir = "${projectDir}/scripts/"
params.datadir = "${projectDir}/data/"
//params.container = "${projectDir}/scripts/rbase-v02.sif"
//params.container = 'ilseclvd/rcontainer/v0.2'
params.container= 'community.wave.seqera.io/library/r-ctrdata_r-dbi_r-dplyr_r-duckdb_pruned:7bf0df866893c97c'

include { train_model } from "./modules/train_module.nf"
include { preprocess }  from "./modules/prep_module.nf"
include { predict }     from "./modules/pred_module.nf"
include { install ; download_data; convert_data }   from "./modules/load_module.nf"

workflow {

def scriptdir = channel.fromPath(params.scriptsdir)
def outdir = channel.fromPath(params.outdir)

install(scriptdir)
download_data(install.out.db_file,scriptdir)
convert_data(download_data.out.db_file,scriptdir)
preprocess(convert_data.out.raw_file,scriptdir)
train_model(preprocess.out.prep_file,scriptdir)
predict(preprocess.out.prep_file,train_model.out.model_file,scriptdir)
write(predict.out.res_file,scriptdir)

println "You can find all following input data, preprocessed data and results file in this folder: "
outdir.view()
def outfiles_csv = channel.fromPath("${params.outdir}/*.csv")
def outfiles_txt = channel.fromPath("${params.outdir}/*.txt")
outfiles_csv.mix(outfiles_txt).collect().view()

write.out.splitText().view()
//write.out.map{p<-file(p).readLines()}
//  .view()
}



process write {
  publishDir params.outdir, mode: 'copy'
  container params.container
  input:
  path(out_file)
  path(scriptsdir)

  output:
  path("prediction_results.txt")

  script:
  """
  Rscript ${scriptsdir}/write.R ${out_file}  .
  """
}