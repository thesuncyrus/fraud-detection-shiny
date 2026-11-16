# fRaud: transaction classification and customer segmentation.
# Original team: Allison Spahn, Himanshu Niraj Sethia, Marissa Urbanek, Chau Nguyen.
numeric_features <- c(
  "current_age", "yearly_income", "total_debt", "credit_score",
  "num_credit_cards", "amount", "credit_limit"
)
category_features <- c("gender", "use_chip", "errors")
feature_names <- c(numeric_features, category_features)
stratified_split <- function(y, fraction = .7, seed = 123) {
  stopifnot(fraction > 0, fraction < 1, !anyNA(y))
  set.seed(seed)
  train <- unlist(lapply(split(seq_along(y), y), function(ids) {
    if (length(ids) < 2) stop("Each class needs at least two observations.")
    sample(ids, max(1, min(length(ids) - 1, floor(length(ids) * fraction))))
  }), use.names = FALSE)
  list(train = sort(train), test = setdiff(seq_along(y), train))
}
fit_schema <- function(d) {
  stopifnot(all(feature_names %in% names(d)))
  medians <- vapply(d[, numeric_features], function(v) {
    if (!is.numeric(v)) stop("Numeric predictors must be numeric.")
    v <- v[is.finite(v)]
    if (!length(v)) stop("All-missing numeric predictor.")
    median(v)
  }, numeric(1))
  levels <- lapply(d[, category_features], function(v) sort(unique(c(as.character(v[!is.na(v)]), "__OTHER__"))))
  list(medians = medians, levels = levels)
}
apply_schema <- function(d, schema) {
  stopifnot(all(feature_names %in% names(d)))
  x <- d[, feature_names, drop = FALSE]
  for (nm in numeric_features) {
    if (!is.numeric(x[[nm]])) stop(paste("Expected numeric:", nm))
    x[[nm]][!is.finite(x[[nm]])] <- schema$medians[[nm]]
  }
  for (nm in category_features) {
    v <- as.character(x[[nm]])
    v[is.na(v) | !v %in% schema$levels[[nm]]] <- "__OTHER__"
    x[[nm]] <- factor(v, levels = schema$levels[[nm]])
  }
  x
}
classification_metrics <- function(y, score, threshold = .5) {
  stopifnot(
    length(y) == length(score), !anyNA(y), all(as.character(y) %in% c("No", "Yes")),
    all(is.finite(score)), all(score >= 0 & score <= 1)
  )
  yes <- as.character(y) == "Yes"
  pred <- score >= threshold
  tp <- sum(yes & pred)
  tn <- sum(!yes & !pred)
  fp <- sum(!yes & pred)
  fn <- sum(yes & !pred)
  div <- function(a, b) if (b > 0) a / b else NA_real_
  n1 <- sum(yes)
  n0 <- sum(!yes)
  auc <- if (n1 && n0) (sum(rank(score)[yes]) - n1 * (n1 + 1) / 2) / (n1 * n0) else NA_real_
  c(
    accuracy = mean(pred == yes), recall = div(tp, tp + fn), precision = div(tp, tp + fp),
    specificity = div(tn, tn + fp), f1 = div(2 * tp, 2 * tp + fp + fn), auc = auc,
    true_positive = tp, true_negative = tn, false_positive = fp, false_negative = fn
  )
}
cluster_customers <- function(d, columns, k) {
  stopifnot(length(columns) == 2, length(unique(columns)) == 2, all(columns %in% names(d)))
  x <- d[, columns, drop = FALSE]
  if (!all(vapply(x, is.numeric, logical(1)))) stop("Choose two numeric fields.")
  x <- x[apply(x, 1, function(v) all(is.finite(v))), , drop = FALSE]
  if (nrow(x) < 3) stop("At least three complete customers are required.")
  if (any(vapply(x, sd, numeric(1)) == 0)) stop("Choose fields with nonzero variance.")
  if (length(k) != 1 || !is.finite(k) || k != as.integer(k) || k < 2 || k >= nrow(unique(x))) stop("Invalid cluster count or too few distinct observations.")
  set.seed(123)
  fit <- kmeans(scale(x), centers = k, nstart = 25, iter.max = 100)
  list(data = x, cluster = fit$cluster, summary = aggregate(x, list(cluster = fit$cluster), mean))
}
