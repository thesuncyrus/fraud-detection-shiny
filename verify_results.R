# Compare an independently completed run to its frozen reference aggregates.
# This script is never called by training or threshold selection.
args <- commandArgs(trailingOnly = TRUE)
out <- if (length(args)) args[1] else "outputs"
expected <- read.csv("results/metrics.csv")
actual <- read.csv(file.path(out, "metrics.csv"))
fields <- c("accuracy", "recall", "precision", "specificity", "f1", "auc",
            "true_positive", "true_negative", "false_positive", "false_negative")
if (!all(fields %in% names(actual)) || nrow(actual) != 1) stop("Invalid computed metrics table.")
delta <- abs(as.numeric(actual[1, fields]) - as.numeric(expected[1, fields]))
report <- data.frame(metric = fields, reference = as.numeric(expected[1, fields]),
                     computed = as.numeric(actual[1, fields]), absolute_difference = delta)
print(report)
if (any(!is.finite(delta)) || any(delta > 1e-8)) stop("Reference mismatch; inspect data hash, versions and split. Do not retune against this reference.")
cat("Frozen RF aggregate metrics reproduced within 1e-8.\n")
