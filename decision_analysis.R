# Prescriptive analysis: select review thresholds for assumed error costs.
# Exploratory comparison of review policies under assumed cost ratios.
# Select thresholds on inner validation, then evaluate once on the fixed outer test.
# Rscript decision_analysis.R Balanced_Processed.csv outputs
source("functions.R"); library(ggplot2)
args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) stop("Usage: Rscript decision_analysis.R input.csv [output-directory]")
out <- if (length(args)>1) args[2] else "outputs"; dir.create(out, recursive = TRUE, showWarnings = FALSE)
d <- read.csv(args[1], stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(!anyNA(d$label), all(d$label %in% c("No", "Yes")))
if ("id" %in% names(d) && anyDuplicated(d$id)) stop("Duplicate transaction IDs.")
y <- factor(d$label, levels = c("No", "Yes")); outer <- stratified_split(y)
inner <- stratified_split(y[outer$train], fraction = .8, seed = 456)
fit_ids <- outer$train[inner$train]; validation_ids <- outer$train[inner$test]; test_ids <- outer$test
stopifnot(!length(intersect(fit_ids, validation_ids)), !length(intersect(validation_ids, test_ids)), !length(intersect(fit_ids, test_ids)))
schema <- fit_schema(d[fit_ids, ]); set.seed(123)
model <- randomForest::randomForest(x = apply_schema(d[fit_ids, ], schema), y = y[fit_ids], ntree = 500, mtry = 3)
v <- as.numeric(predict(model, apply_schema(d[validation_ids, ], schema), type = "prob")[, "Yes"])
# The threshold grid includes policies flagging all / none. Ties favor fewer alerts.
grid <- c(0, seq(.02, 1, by = .02), 1.01)
validation <- do.call(rbind, lapply(grid, function(t) data.frame(threshold = t, t(classification_metrics(y[validation_ids], v, t)), row.names = NULL)))
settings <- do.call(rbind, lapply(c(1, 5, 10), function(ratio) {
  cost <- validation$false_positive + ratio * validation$false_negative
  chosen <- tail(which(cost == min(cost)), 1)
  data.frame(fn_to_fp_cost = ratio, selected_threshold = validation$threshold[chosen], validation_cost = cost[chosen])
}))
# Thresholds are now fixed. No model refit or outer-test threshold selection.
score <- as.numeric(predict(model, apply_schema(d[test_ids, ], schema), type = "prob")[, "Yes"])
results <- do.call(rbind, lapply(seq_len(nrow(settings)), function(i) {
  setting <- settings[i, ]; rows <- lapply(c("Fixed 0.50", "Validation-selected"), function(policy) {
    threshold <- if (policy == "Fixed 0.50") .5 else setting$selected_threshold
    m <- classification_metrics(y[test_ids], score, threshold)
    data.frame(fn_to_fp_cost = setting$fn_to_fp_cost, policy = policy, threshold = threshold,
      test_n = length(test_ids), recall = unname(m["recall"]), precision = unname(m["precision"]),
      flagged = unname(m["true_positive"] + m["false_positive"]),
      false_positive = unname(m["false_positive"]), false_negative = unname(m["false_negative"]),
      cost_per_1000 = 1000 * unname(m["false_positive"] + setting$fn_to_fp_cost * m["false_negative"]) / length(test_ids))
  }); do.call(rbind, rows)
}))
write.csv(settings, file.path(out, "policy-settings.csv"), row.names = FALSE)
write.csv(validation, file.path(out, "policy-validation.csv"), row.names = FALSE)
write.csv(results, file.path(out, "policy-results.csv"), row.names = FALSE)
theme_set(theme_minimal(base_size = 12) + theme(panel.grid.minor = element_blank(), plot.background = element_rect(fill = "#faf9f6", colour = NA)))
ggsave(file.path(out, "fraud-cost-policy.svg"), ggplot(results, aes(factor(fn_to_fp_cost), cost_per_1000, fill = policy)) +
  geom_col(position = "dodge", width = .65) + scale_fill_manual(values = c("Fixed 0.50" = "#a8aca8", "Validation-selected" = "#2a5663")) +
  labs(title = "Error costs change the review policy", x = "Assumed missed-fraud cost / false-alert cost", y = "Cost units per 1,000 test transactions", fill = NULL,
    caption = "Illustrative costs, balanced sample. Separate model trained on 14,000 rows; 3,500 validation and 7,500 test rows.") +
  theme(legend.position = "top"), width = 9, height = 5, device = grDevices::svg)
writeLines(c("Cost units are assumptions, not measured financial loss.",
  "Outer holdout matches train.R; this analysis fits a separate model on the inner training subset.",
  "Previously examined outer holdout is reused for transparent comparison, not fresh external validation.",
  "Selected thresholds use inner validation labels only; no operational policy is asserted.",
  paste("Input MD5:", tools::md5sum(args[1])), capture.output(sessionInfo())), file.path(out, "decision-run-info.txt"))
print(results)
