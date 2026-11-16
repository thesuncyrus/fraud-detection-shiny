# Rscript train.R /path/to/Balanced_Processed.csv outputs
source("functions.R")
args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) stop("Usage: Rscript train.R input.csv [output-directory]")
out <- if (length(args) > 1) args[2] else "outputs"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
if (!requireNamespace("randomForest", quietly = TRUE)) stop("Install randomForest.")
d <- read.csv(args[1], stringsAsFactors = FALSE, check.names = FALSE)
stopifnot("label" %in% names(d), !anyNA(d$label), all(d$label %in% c("No", "Yes")))
# Transaction identifiers are excluded from all predictors.
if ("id" %in% names(d) && (anyNA(d$id) || anyDuplicated(d$id))) stop("Missing or duplicate transaction IDs found.")
y <- factor(d$label, levels = c("No", "Yes"))
p <- stratified_split(y)
schema <- fit_schema(d[p$train, ])
xtr <- apply_schema(d[p$train, ], schema)
xte <- apply_schema(d[p$test, ], schema)
set.seed(123)
model <- randomForest::randomForest(x = xtr, y = y[p$train], ntree = 500, mtry = 3, importance = TRUE)
score <- as.numeric(predict(model, xte, type = "prob")[, "Yes"])
m <- classification_metrics(y[p$test], score)
write.csv(as.data.frame(as.list(m)), file.path(out, "metrics.csv"), row.names = FALSE)
imp <- randomForest::importance(model, type = 2)
write.csv(data.frame(feature = rownames(imp), importance = imp[, 1]), file.path(out, "importance.csv"), row.names = FALSE)
# Retain prediction-level data locally; the website shows aggregate results only.
write.csv(data.frame(actual = y[p$test], score = score), file.path(out, "predictions.csv"), row.names = FALSE)
saveRDS(list(model = model, schema = schema, metrics = m), file.path(out, "model.rds"))
writeLines(c(
  "Evaluation: stratified 70/30 transaction holdout on the pre-balanced dataset.",
  "Positive class: Yes. Random transaction split does not establish unseen-customer or future performance.",
  "Class prevalence is 50% in the supplied data; probability scores are not calibrated to deployment prevalence.",
  paste("Input MD5:", tools::md5sum(args[1])), capture.output(sessionInfo())
), file.path(out, "run-info.txt"))
print(m)
