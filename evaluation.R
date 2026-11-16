# ROC, precision-recall and feature-importance figures from the recorded holdout.
# Rscript evaluation.R outputs
source("functions.R"); library(ggplot2)
args <- commandArgs(trailingOnly = TRUE); out <- if (length(args)) args[1] else "outputs"
p <- read.csv(file.path(out, "predictions.csv")); imp <- read.csv(file.path(out, "importance.csv"))
thresholds <- c(Inf, sort(unique(p$score), decreasing = TRUE), -Inf)
curve <- do.call(rbind, lapply(thresholds, function(t) {
  m <- classification_metrics(p$actual, p$score, t)
  data.frame(threshold = t, recall = unname(m["recall"]), precision = unname(m["precision"]), fpr = 1-unname(m["specificity"]))
}))
write.csv(curve, file.path(out, "roc-pr-points.csv"), row.names = FALSE)
theme_set(theme_minimal(base_size = 12) + theme(panel.grid.minor = element_blank(),
  plot.background = element_rect(fill = "#faf9f6", colour = NA)))
ggsave(file.path(out, "fraud-roc.svg"), ggplot(curve, aes(fpr, recall)) + geom_path(colour = "#2a5663", linewidth = 1) +
  geom_abline(slope = 1, intercept = 0, linetype = 2, colour = "#999999") + coord_equal() +
  labs(title = "ROC curve", x = "False positive rate", y = "Fraud recall",
    caption = "Random forest: 7,500 held-out transactions from the balanced dataset."), width = 6, height = 5, device = grDevices::svg)
ggsave(file.path(out, "fraud-pr.svg"), ggplot(subset(curve, is.finite(precision)), aes(recall, precision)) +
  geom_path(colour = "#2a5663", linewidth = 1) + geom_hline(yintercept = mean(p$actual == "Yes"), linetype = 2, colour = "#999999") +
  coord_cartesian(xlim = c(0,1), ylim = c(0,1)) + labs(title = "Precision–recall curve", x = "Fraud recall", y = "Precision",
    caption = "Precision reflects the 50% fraud prevalence of this holdout."), width = 6, height = 5, device = grDevices::svg)
ggsave(file.path(out, "fraud-importance.svg"), ggplot(imp, aes(reorder(feature, importance), importance)) +
  geom_col(fill = "#2a5663", width = .65) + coord_flip() +
  labs(title = "Which signals the forest uses", x = NULL, y = "Mean decrease in Gini",
    caption = "Training-model impurity importance; not causal and potentially biased toward variables with more split points."),
  width = 9, height = 5, device = grDevices::svg)
