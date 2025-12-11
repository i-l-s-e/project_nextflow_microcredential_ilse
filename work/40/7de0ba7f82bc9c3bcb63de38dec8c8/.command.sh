#!/bin/bash -ue
Rscript scripts/predict.R prepared_data.csv model_deaths.rds .
