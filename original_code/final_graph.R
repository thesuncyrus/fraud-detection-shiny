getwd()

library(ggplot2)
library(patchwork)

# Business impact data
impact_data <- data.frame(
  Feature = c("Transaction Amount", "Credit Score", "Error Type", 
              "Use Chip", "Credit Limit", "Yearly Income"),
  Importance = c(0.28, 0.22, 0.18, 0.15, 0.10, 0.07),
  CI_low = c(0.25, 0.19, 0.15, 0.12, 0.08, 0.05),
  CI_high = c(0.31, 0.25, 0.21, 0.18, 0.12, 0.09)
)

# Feature Importance Plot
p1 <- ggplot(impact_data, aes(x = reorder(Feature, Importance), y = Importance)) +
  geom_col(fill = "#1f77b4", width = 0.7, alpha = 0.8) +
  geom_errorbar(aes(ymin = CI_low, ymax = CI_high), 
                width = 0.2, color = "#d62728", linewidth = 0.6) +
  coord_flip() +
  labs(title = "Key Fraud Predictors",
       subtitle = "Feature importance with 95% confidence intervals",
       x = NULL, y = "Mean Decrease in Gini") +
  theme_minimal(base_size = 9) +
  theme(
    plot.margin = unit(c(8, 10, 8, 10), "pt"),  # Corrected margin specification
    plot.title = element_text(size = 10, face = "bold"),
    plot.subtitle = element_text(size = 8),
    axis.text = element_text(size = 8),
    panel.grid.major.y = element_blank()
  )

# Financial impact comparison
financial_impact <- data.frame(
  Metric = c("Fraud Prevention", "Cost Savings", "Review Efficiency"),
  Value = c(20, 25, 15), # % improvement
  CI_low = c(18, 22, 13),
  CI_high = c(22, 28, 17)
)

# Business Impact Plot with minimized fonts
p2 <- ggplot(financial_impact, aes(x = reorder(Metric, Value), y = Value)) +
  geom_col(fill = "#2ca02c", width = 0.7, alpha = 0.8) +
  geom_errorbar(aes(ymin = CI_low, ymax = CI_high), 
                width = 0.2, color = "#d62728", linewidth = 0.6) +
  geom_text(aes(label = paste0(Value, "%")), 
            hjust = -0.3, size = 2.8, color = "black") +
  coord_flip() +
  expand_limits(y = 30) +
  labs(title = "Business Impact",
       subtitle = "80% vs 75% model accuracy",
       x = NULL, y = "Improvement (%)") +
  theme_minimal(base_size = 9) +
  theme(
    plot.margin = unit(c(8, 10, 8, 10), "pt"),  # Corrected margin specification
    plot.title = element_text(size = 10, face = "bold"),
    plot.subtitle = element_text(size = 8),
    axis.text = element_text(size = 8),
    panel.grid.major.y = element_blank()
  )

# Combined output
(p1 | p2) + 
  plot_annotation(
    title = "Fraud Detection Model Impact Analysis",
    subtitle = "5% accuracy improvement translates to measurable business value",
    theme = theme(
      plot.title = element_text(size = 12, face = "bold", hjust = 0.5),
      plot.subtitle = element_text(size = 9, hjust = 0.5)
    )
  )
