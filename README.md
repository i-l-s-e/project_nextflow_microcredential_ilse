
# Nextflow Workflow: A Clinical Trial Application
# Data Preparation, Model Training, and Prediction

## Overview
This pipeline automates the following steps:
1. **Install local server to imitate a redshift SQL or AWS SQL kind of server**
2. **Download public data from clinical trials (ctgov)** 
3. **convert data into a workable csv file**
4. **Preprocess data**
5. **Train a predictive model**
6. **Generate predictions**
7. **Write results to output files**

The workflow uses **Nextflow DSL2** and runs R scripts inside a container for reproducibility.

---

## Requirements
- **Nextflow** (version ≥ 22.10 recommended)
- **Apptainer** or **Docker** (for container execution is enabled)
- **R scripts** located in `scripts/`
- **Modules** located in `modules/`

---

## Pipeline Structure
Modules included:
- `load_module.nf` → `install`, `download_data`, `convert_data`
- `prep_module.nf` → `preprocess`
- `train_module.nf` → `train_model`
- `pred_module.nf` → `predict`

Final process:
- `write` → saves prediction results to `params.outdir/predictive_results.txt`
---

## Configuration
Default parameters in `main.nf`:
```groovy
params.outdir    = "${projectDir}/output"
params.scriptsdir = "${projectDir}/scripts/"
params.datadir    = "${projectDir}/data/"
params.container  = 'community.wave.seqera.io/library/r-ctrdata_r-dbi_r-dplyr_r-duckdb_pruned:7bf0df866893c97c'
```

## Running the pipeline
```groovy
nextflow run main.nf
```
you can also run on a profile as HPC
```groovy
nextflow run main.nf -profile HPC
```

## Outputs 
all outputs are saved in:
```groovy
${params.outdir}/
```
Including 
- the raw data
- preprocessed data
- model file
- prediction results
- results for each individual prediction

The workflow it self prints the predictions and the files where all is located


