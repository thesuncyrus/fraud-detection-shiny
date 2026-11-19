# Optional comparison against the fixed original confusion matrix.
# From the repository root: Rscript tests/reference_results.R outputs/model.rds
# Reads an existing model bundle only; does not fit a model or run with train.R.
args <- commandArgs(trailingOnly = TRUE)
path <- if (length(args)) args[1] else Sys.getenv("FRAUD_MODEL_PATH", "outputs/model.rds")
b <- readRDS(path)
stopifnot(identical(as.integer(b$confusion), c(3220L, 530L, 561L, 3189L)))
cat("Original confusion-matrix reference check passed.\n")
