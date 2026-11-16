# Produce application-facing wording from one computed evaluation.
source("functions.R")
args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args)) args[1] else "outputs"
p <- read.csv(file.path(out, "predictions.csv"))
actual <- classification_metrics(p$actual, p$score)
stored <- read.csv(file.path(out, "metrics.csv"))
stopifnot(nrow(stored) == 1,
          isTRUE(all.equal(unname(actual), as.numeric(stored[1, names(actual)]), tolerance = 1e-10)))
summary <- c(
  sprintf("Random Forest detected approximately %.0f%% of fraudulent transactions in the held-out balanced test set (ROC AUC = %.2f).",
          100 * actual["recall"], actual["auc"]),
  sprintf("Exact evaluation: accuracy %.4f; fraud recall %.7f; ROC AUC %.7f; test transactions %d.",
          actual["accuracy"], actual["recall"], actual["auc"], nrow(p)),
  "Positive class: Yes. Recall = TP/(TP+FN). Accuracy = (TP+TN)/N.",
  "The 70/30 random transaction split uses data balanced before splitting."
)
writeLines(summary, file.path(out, "summary.txt"))
cat(paste(summary, collapse = "\n"), "\n")
