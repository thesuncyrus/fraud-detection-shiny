# Standardized customer segmentation, matching the Shiny application.
# Rscript segmentation.R customers.csv outputs
source("functions.R"); library(ggplot2)
args <- commandArgs(trailingOnly = TRUE)
if (!length(args)) stop("Usage: Rscript segmentation.R customers.csv [output-directory]")
out <- if (length(args) > 1) args[2] else "outputs"; dir.create(out, recursive = TRUE, showWarnings = FALSE)
d <- read.csv(args[1]); columns <- c("current_age", "avg_transaction_amount")
result <- cluster_customers(d, columns, 3)
profile <- result$summary
profile$n <- as.integer(table(factor(result$cluster, levels = profile$cluster)))
write.csv(profile, file.path(out, "cluster-profile.csv"), row.names = FALSE)
write.csv(data.frame(input_customers = nrow(d), complete_customers = nrow(result$data), k = 3,
  x = columns[1], y = columns[2]), file.path(out, "cluster-audit.csv"), row.names = FALSE)
x <- scale(result$data)
elbow <- do.call(rbind, lapply(1:min(10, nrow(unique(x))-1), function(k) {
  set.seed(123); fit <- kmeans(x, centers = k, nstart = 25, iter.max = 100)
  data.frame(k = k, within_cluster_ss = fit$tot.withinss)
}))
write.csv(elbow, file.path(out, "cluster-elbow.csv"), row.names = FALSE)
theme_set(theme_minimal(base_size = 12) + theme(panel.grid.minor = element_blank(),
  plot.background = element_rect(fill = "#faf9f6", colour = NA)))
ggsave(file.path(out, "fraud-clusters.svg"), ggplot(profile, aes(current_age, avg_transaction_amount)) +
  geom_point(aes(size = n), colour = "#2a5663", alpha = .65) +
  geom_text(aes(label = paste("Group", cluster)), vjust = -1.4, size = 4) +
  scale_size_area(max_size = 16) + expand_limits(y = max(profile$avg_transaction_amount)*1.2) +
  labs(title = "Three customer profiles", x = "Mean customer age", y = "Mean transaction amount", size = "Customers",
    caption = "Cluster centroids only; k = 3 illustrates the app default, not an established optimum. No fraud labels inferred."),
  width = 9, height = 5, device = grDevices::svg)
ggsave(file.path(out, "fraud-elbow.svg"), ggplot(elbow, aes(k, within_cluster_ss)) +
  geom_line(colour = "#2a5663") + geom_point(colour = "#2a5663") + scale_x_continuous(breaks = elbow$k) +
  labs(title = "Cluster-count sensitivity", x = "Number of clusters", y = "Within-cluster sum of squares",
    caption = "Age and mean transaction amount are standardized before k-means."), width = 8, height = 4, device = grDevices::svg)
writeLines(c(paste("Input MD5:", tools::md5sum(args[1])), capture.output(sessionInfo())), file.path(out, "segmentation-run-info.txt"))
print(profile)
