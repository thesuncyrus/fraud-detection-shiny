# Logistic comparator on exactly the RF holdout; coefficients trained without test labels.
source("functions.R")
args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) stop("Usage: Rscript baseline.R Balanced_Processed.csv [output-directory]")
out <- if (length(args) > 1) args[2] else "outputs"
dir.create(out, recursive = TRUE, showWarnings = FALSE)
d <- read.csv(args[1], check.names = FALSE)
if (anyNA(d$label) || !all(d$label %in% c("No", "Yes"))) stop("Invalid labels.")
if ("id" %in% names(d) && (anyNA(d$id) || anyDuplicated(d$id))) stop("Invalid transaction IDs.")
y <- factor(d$label, levels = c("No", "Yes")); s <- stratified_split(y)
schema <- fit_schema(d[s$train, ])
tr <- apply_schema(d[s$train, ], schema); te <- apply_schema(d[s$test, ], schema)
# Standardize numerical values before QR checks and IRLS to avoid unit-driven
# numerical rank loss (income/debt are much larger than binary indicators).
for (nm in numeric_features) {
  center <- mean(tr[[nm]]); spread <- sd(tr[[nm]])
  if (!is.finite(spread) || spread == 0) spread <- 1
  tr[[nm]] <- (tr[[nm]] - center) / spread
  te[[nm]] <- (te[[nm]] - center) / spread
}
# Explicit model matrix includes the fallback category, then removes constant
# training columns. Test-only levels cannot create untrained coefficients.
train_matrix <- model.matrix(~ ., tr); test_matrix <- model.matrix(~ ., te)
keep <- colnames(train_matrix) == "(Intercept)" | apply(train_matrix, 2, sd) > 0
train_matrix <- train_matrix[, keep, drop = FALSE]; test_matrix <- test_matrix[, keep, drop = FALSE]
qr_fit <- qr(train_matrix, tol = 1e-10)
independent <- qr_fit$pivot[seq_len(qr_fit$rank)]
# A fallback factor level absent in training can otherwise leave a full set of
# observed-category dummies plus intercept. Remove dependent columns on train.
train_matrix <- train_matrix[, independent, drop = FALSE]
test_matrix <- test_matrix[, independent, drop = FALSE]
fit <- glm.fit(train_matrix, as.numeric(y[s$train] == "Yes"), family = binomial())
if (!fit$converged || anyNA(fit$coefficients)) stop("Logistic model failed to converge or is rank deficient.")
score <- plogis(as.numeric(test_matrix %*% fit$coefficients))
m <- classification_metrics(y[s$test], score)
write.csv(as.data.frame(as.list(m)), file.path(out, "logistic-metrics.csv"), row.names = FALSE)
write.csv(data.frame(feature = names(fit$coefficients), coefficient = fit$coefficients),
          file.path(out, "logistic-coefficients.csv"), row.names = FALSE)
writeLines(c("New paired logistic comparator; does not claim to reproduce poster AUC 0.7193.",
             paste("Converged:", fit$converged), capture.output(sessionInfo())), file.path(out, "logistic-run-info.txt"))
print(m)
