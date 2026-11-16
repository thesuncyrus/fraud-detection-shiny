# Descriptive statistics, quality audit, transaction-channel EDA and amount plots.
# Rscript eda.R Balanced_Processed.csv outputs
source("functions.R")
library(ggplot2)
args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) stop("Usage: Rscript eda.R input.csv [output-directory]")
out <- if (length(args) > 1) args[2] else "outputs"; dir.create(out, recursive = TRUE, showWarnings = FALSE)
d <- read.csv(args[1], stringsAsFactors = FALSE, check.names = FALSE)
stopifnot(all(c(feature_names, "label") %in% names(d)), !anyNA(d$label), all(d$label %in% c("No", "Yes")))
if ("id" %in% names(d) && anyDuplicated(d$id)) stop("Duplicate transaction IDs.")
# Audit the supplied experiment; distributional EDA is limited to the training partition.
p <- stratified_split(factor(d$label, levels = c("No", "Yes"))); tr <- d[p$train, ]
audit <- data.frame(field = names(d), missing = vapply(d, function(x) sum(is.na(x)), integer(1)),
  distinct_observed = vapply(d, function(x) length(unique(x[!is.na(x)])), integer(1)))
write.csv(audit, file.path(out, "data-audit.csv"), row.names = FALSE)
summaries <- do.call(rbind, lapply(c("No", "Yes"), function(label) do.call(rbind, lapply(numeric_features, function(nm) {
  x <- tr[tr$label == label, nm]; x <- x[is.finite(x)]
  data.frame(label = label, feature = nm, n = length(x), mean = mean(x), sd = sd(x), median = median(x),
    p25 = unname(quantile(x, .25)), p75 = unname(quantile(x, .75)), min = min(x), max = max(x))
}))))
write.csv(summaries, file.path(out, "numeric-summary.csv"), row.names = FALSE)
categories <- do.call(rbind, lapply(category_features, function(nm) {
  table <- as.data.frame(table(category = tr[[nm]], label = tr$label)); table$feature <- nm; table
}))
write.csv(categories, file.path(out, "category-summary.csv"), row.names = FALSE)
channels <- do.call(rbind, lapply(split(tr, tr$use_chip), function(g) data.frame(
  channel = g$use_chip[1], n = nrow(g), fraud_n = sum(g$label == "Yes"), fraud_share = mean(g$label == "Yes"))))
write.csv(channels, file.path(out, "channel-summary.csv"), row.names = FALSE)
theme_set(theme_minimal(base_size = 12) + theme(panel.grid.minor = element_blank(),
  plot.background = element_rect(fill = "#faf9f6", colour = NA)))
save_plot <- function(name, p, height = 5) ggsave(file.path(out, name), p, width = 9, height = height, device = grDevices::svg)
save_plot("fraud-channels.svg", ggplot(channels, aes(reorder(channel, fraud_share), fraud_share)) +
  geom_col(fill = "#2a5663", width = .55) + coord_flip() + scale_y_continuous(labels = function(x) paste0(round(100*x), "%"), limits = c(0, 1)) +
  labs(title = "Transaction channel separates the two classes", x = NULL, y = "Fraud share within channel",
    caption = "Training partition of a 50/50 balanced sample. These are not population fraud rates."))
# Preserve negative amounts; their meaning cannot be inferred from values alone.
breaks <- c(-Inf, 0, 25, 50, 100, 250, 500, Inf)
tr$amount_band <- cut(tr$amount, breaks = breaks, right = FALSE,
  labels = c("Negative", "0–<25", "25–<50", "50–<100", "100–<250", "250–<500", "500+"))
amount <- as.data.frame(table(band = tr$amount_band, label = tr$label))
amount$within_class_share <- ave(amount$Freq, amount$label, FUN = function(x) x/sum(x))
write.csv(amount, file.path(out, "amount-summary.csv"), row.names = FALSE)
save_plot("fraud-amounts.svg", ggplot(amount, aes(band, within_class_share, fill = label)) +
  geom_col(position = "dodge", width = .7) + scale_fill_manual(values = c("No" = "#2a5663", "Yes" = "#b57550"), labels = c("Legitimate", "Fraud")) +
  scale_y_continuous(labels = function(x) paste0(round(100*x), "%")) +
  labs(title = "Transaction amount distributions", x = "Amount band (dataset currency units)", y = "Share within class", fill = NULL,
    caption = "Training partition only. Negative amounts are retained, not assumed to be errors.") + theme(legend.position = "top"))
writeLines(c("Data audit uses all supplied rows; descriptive class comparisons use training rows only.",
  paste("Training rows:", nrow(tr)), paste("Input MD5:", tools::md5sum(args[1])), capture.output(sessionInfo())), file.path(out, "eda-run-info.txt"))
print(channels)
