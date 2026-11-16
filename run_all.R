# One command for the supplied processed-data route; raw preparation is separate.
args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) stop("Usage: Rscript run_all.R Balanced_Processed.csv [outputs] [customers.csv]")
input <- normalizePath(args[1], mustWork = TRUE)
out <- if (length(args) > 1) args[2] else "outputs"
dir.create(out, recursive = TRUE, showWarnings = FALSE); out <- normalizePath(out)
if (!dir.exists(out)) stop("Output must be a directory; customers.csv is the third argument.")
rscript <- file.path(R.home("bin"), "Rscript")
run <- function(script, ...) {
  code <- system2(rscript, shQuote(c(script, ...)))
  if (code != 0) stop(paste("Failed:", script))
}
run("tests.R")
run("eda.R", input, out)
run("train.R", input, out)
run("report_summary.R", out)
run("baseline.R", input, out)
run("plot.R", out)
run("evaluation.R", out)
if (length(args) > 2) run("segmentation.R", normalizePath(args[3], mustWork = TRUE), out)
# Additional policy experiment is deliberately separate from the historical result.
run("decision_analysis.R", input, out)
Sys.setenv(FRAUD_MODEL_PATH = file.path(out, "model.rds"))
if (length(args) > 2) Sys.setenv(FRAUD_CUSTOMERS_PATH = normalizePath(args[3]))
run("smoke-test.R")
cat("Analysis, baseline, plots, policy extension and Shiny integration completed.\n")
