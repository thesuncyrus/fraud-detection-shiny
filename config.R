# Existing experiment settings; no RNG calls or preprocessing occur on import.
fraud_config <- list(
  predictors = c("current_age", "gender", "yearly_income", "total_debt",
    "credit_score", "num_credit_cards", "amount", "use_chip", "errors", "credit_limit"),
  forest = list(seed = 123, train_fraction = .7, ntree = 500, mtry = 3),
  logistic = list(seed = 123, train_fraction = .7, formula = label ~ ., threshold = .5),
  preparation = list(seed = 123, observations_per_class = 12500),
  clustering = list(nstart = 5, iter.max = 20)
)
# Forest excludes id; logistic keeps id. Numeric category coding and unscaled
# k-means remain in src/fraud_model.R. Forest settings spell out existing defaults.
