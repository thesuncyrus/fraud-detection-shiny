# Historical transaction classifier: preserve column order, encoding and RNG order.
read_transactions <- function(path) {
  if (!file.exists(path)) stop("Supply an authorized Balanced_Processed.csv.")
  d <- read.csv(path, stringsAsFactors = FALSE)
  expected <- c("label", "current_age", "gender", "yearly_income", "total_debt",
                "credit_score", "num_credit_cards", "amount", "use_chip", "errors", "credit_limit")
  d$id <- NULL
  if (!identical(names(d), expected)) stop("Columns/order differ from the historical input contract.")
  if (anyNA(d)) stop("Missing values were not part of the supplied historical input.")
  if (!setequal(unique(d$label), c("No", "Yes"))) stop("Expected No/Yes labels.")
  d$label <- as.factor(d$label)
  categories <- names(d)[vapply(d, is.character, logical(1))]
  levels <- lapply(d[categories], function(x) levels(as.factor(x)))
  for (name in categories) d[[name]] <- as.numeric(as.factor(d[[name]]))
  list(data=d, levels=levels)
}
fit_historical_forest <- function(path) {
  for (pkg in c("caret", "randomForest", "pROC"))
    if (!requireNamespace(pkg, quietly=TRUE)) stop(paste("Install", pkg))
  input <- read_transactions(path)
  d <- input$data
  set.seed(123)
  index <- caret::createDataPartition(d$label, p=.7, list=FALSE)
  training <- d[index, ]
  test <- d[-index, ]
  # Do not reseed, reorder features or enable importance=TRUE: these alter the fit.
  forest <- randomForest::randomForest(label ~ ., data=training)
  predicted <- predict(forest, test, type="response")
  scores <- predict(forest, test, type="prob")[, "Yes"]
  cm <- caret::confusionMatrix(predicted, test$label, positive="Yes")
  roc <- pROC::roc(test$label, scores, levels=c("No","Yes"), direction="<", quiet=TRUE)
  metrics <- c(accuracy=unname(cm$overall['Accuracy']), recall=unname(cm$byClass['Sensitivity']),
               precision=unname(cm$byClass['Pos Pred Value']), specificity=unname(cm$byClass['Specificity']),
               f1=unname(cm$byClass['F1']), roc_auc=as.numeric(pROC::auc(roc)))
  list(model=forest, levels=input$levels, features=setdiff(names(d),'label'),
       defaults=vapply(training[setdiff(names(d),'label')], median, numeric(1)),
       metrics=metrics, confusion=cm$table, roc=roc,
       train_n=nrow(training), test_n=nrow(test), test_scores=scores, test_truth=test$label)
}
encode_observation <- function(values, bundle) {
  if (!all(bundle$features %in% names(values))) stop("Missing named predictors.")
  d <- as.data.frame(values[bundle$features], stringsAsFactors=FALSE)
  for (name in names(bundle$levels)) {
    if (!as.character(d[[name]]) %in% bundle$levels[[name]]) stop(paste("Unknown category:", name))
    d[[name]] <- match(d[[name]], bundle$levels[[name]])
  }
  if (any(!vapply(d, function(x) is.numeric(x) && length(x)==1 && is.finite(x), logical(1))))
    stop("Every numeric predictor must be finite.")
  d
}
cluster_customers <- function(customers, fields, k) {
  if (length(unique(fields)) != 2) stop("Choose two different fields.")
  d <- customers[,fields,drop=FALSE]
  if (!all(vapply(d,is.numeric,logical(1))) || anyNA(d)) stop("Use complete numeric fields.")
  if (nrow(unique(d)) < k) stop("Too few distinct observations.")
  # Preserve original units, iteration limit, starts and stochastic interaction.
  fit <- kmeans(d, centers=k, iter.max=20, nstart=5)
  list(data=d, fit=fit, summary=aggregate(d,list(cluster=fit$cluster),mean))
}
