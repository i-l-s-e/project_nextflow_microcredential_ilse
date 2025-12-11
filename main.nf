nextflow.enable.dsl=2


params.outdir = "${projectDir}/output"
params.scriptsdir = "${projectDir}/scripts/"
params.datadir = "${projectDir}/data/"
params.condition = "HER2-positive metastatic breast cancer"
params.split = 0.8 //this is the split in which the data will be divided as in 80% training set and 20% validation set, 
//if put to 100% then all data is used for training, you can manually fill in a rawdata_val.csv to make a prediction of a new study
//params.container = "${projectDir}/scripts/rbase-v02.sif"
//params.container = 'ilseclvd/rcontainer/v0.2'
params.container= 'community.wave.seqera.io/library/r-ctrdata_r-dbi_r-dplyr_r-duckdb_pruned:7bf0df866893c97c'

include { train_model } from "./modules/train_module.nf"
include { preprocess as preprocess_train; preprocess as preprocess_val }  from "./modules/prep_module.nf"
include { predict }     from "./modules/pred_module.nf"
include { install ; download_data; convert_data }   from "./modules/load_module.nf"

workflow {


def outdir = channel.fromPath(params.outdir)
def cond   = channel.value(params.condition)
def split   = channel.value(params.split)


install()
download_data(install.out.db_file,cond)
convert_data(download_data.out.db_file,split)
preprocess_train(convert_data.out.raw_file)
preprocess_val(convert_data.out.raw_val_file)
train_model(preprocess_train.out.prep_file)
predict(preprocess_val.out.prep_file,train_model.out.model_file)
write(predict.out.res_file)

    println "You can find all following input data, preprocessed data and results file in this folder: "
    outdir.view()
    def outfiles_csv = channel.fromPath("${params.outdir}/*.csv")
    def outfiles_txt = channel.fromPath("${params.outdir}/*.txt")
    outfiles_csv.mix(outfiles_txt).collect().view()

    write.out.splitText().view()
}
//write.out.map{p<-file(p).readLines()}
//  .view()




process write {
  publishDir params.outdir, mode: 'copy'
  container params.container
  input:
  path(out_file)

  output:
  path("prediction_results.txt")

  script:
  """
  Rscript ${params.scriptsdir}/write.R ${out_file}  .
  """
}