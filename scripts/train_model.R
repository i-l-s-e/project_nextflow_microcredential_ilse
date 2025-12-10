#!/usr/bin/env Rscript
args <- commandArgs(trailingOnly=TRUE)
input_csv <- args[1]
outfile <- args[2]

library(dplyr)
library(ranger)

set.seed(42)
data <- read.csv(input_csv, stringsAsFactors = FALSE)

# make a toy target: length of brief_title > median
if(nrow(data) < 10){
  write.csv(data.frame(), outfile, row.names=FALSE)
  quit(status=0)
}

data$target <- as.integer(nchar(data$brief_title) > median(nchar(data$brief_title), na.rm=TRUE))

# simple features: title_len, cond_count
feat <- data %>%
  mutate(title_len = nchar(brief_title), cond_count = ifelse(condition=='',0, 1 + str_count(condition, ';'))) %>%
  select(title_len, cond_count, target) %>%
  na.omit()

train_idx <- sample(seq_len(nrow(feat)), size = floor(0.8 * nrow(feat)))
train <- feat[train_idx,]
test <- feat[-train_idx,]

rf <- ranger::ranger(target ~ ., data = train, num.trees = 50)
pred <- predict(rf, data = test)$predictions

out <- data.frame(obs = test$target, pred = pred)
write.csv(out, outfile, row.names=FALSE)
cat('Wrote predictions to', outfile, '\n')