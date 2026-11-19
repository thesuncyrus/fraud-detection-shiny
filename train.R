source("src/fraud_model.R")
args <- commandArgs(trailingOnly=TRUE)
input <- if(length(args)) args[1] else "data/Balanced_Processed.csv"
out <- if (length(args)>1) args[2] else "outputs"
dir.create(out, recursive=TRUE, showWarnings=FALSE)
b <- fit_forest(input)
write.csv(data.frame(metric=names(b$metrics),value=unname(b$metrics),status="test"),
          file.path(out,"metrics.csv"),row.names=FALSE)
write.csv(as.data.frame(b$confusion), file.path(out,"confusion.csv"),row.names=FALSE)
write.csv(data.frame(false_positive_rate=1-b$roc$specificities,true_positive_rate=b$roc$sensitivities),
          file.path(out,"roc.csv"),row.names=FALSE)
imp <- randomForest::importance(b$model,type=2)
write.csv(data.frame(feature=rownames(imp),mean_decrease_gini=imp[,1]),file.path(out,"importance.csv"),row.names=FALSE)
writeLines(c("Seed 123, numeric categorical coding, 70/30 stratified split, default RF.",
             paste("train",b$train_n,"test",b$test_n),capture.output(sessionInfo())),file.path(out,"run-info.txt"))
# Fitted models and individual predictions remain private.
b$test_scores <- b$test_truth <- b$roc <- NULL
saveRDS(b,file.path(out,"model.rds"))
print(b$metrics)
cat("Model evaluation completed.\n")
