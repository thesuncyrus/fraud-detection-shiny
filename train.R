source("src/fraud_model.R")
args <- commandArgs(trailingOnly=TRUE)
if (!length(args)) stop("Usage: Rscript train.R /private/Balanced_Processed.csv [outputs]")
out <- if (length(args)>1) args[2] else "outputs"
dir.create(out, recursive=TRUE, showWarnings=FALSE)
b <- fit_historical_forest(args[1])
write.csv(data.frame(metric=names(b$metrics),value=unname(b$metrics),status="reproduced"),
          file.path(out,"metrics.csv"),row.names=FALSE)
write.csv(as.data.frame(b$confusion), file.path(out,"confusion.csv"),row.names=FALSE)
write.csv(data.frame(false_positive_rate=1-b$roc$specificities,true_positive_rate=b$roc$sensitivities),
          file.path(out,"roc.csv"),row.names=FALSE)
imp <- randomForest::importance(b$model,type=2)
write.csv(data.frame(feature=rownames(imp),mean_decrease_gini=imp[,1]),file.path(out,"importance.csv"),row.names=FALSE)
writeLines(c("Original seed 123, numeric categorical coding, 70/30 stratified split, default RF.",
             paste("train",b$train_n,"test",b$test_n),capture.output(sessionInfo())),file.path(out,"run-info.txt"))
# Fitted models and individual predictions remain private.
b$test_scores <- b$test_truth <- b$roc <- NULL
saveRDS(b,file.path(out,"model.rds"))
print(b$metrics)
stopifnot(identical(as.integer(b$confusion),c(3220L,530L,561L,3189L)))
cat("Original poster confusion matrix reproduced.\n")
