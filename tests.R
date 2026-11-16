source("functions.R")
y <- factor(rep(c("No", "Yes"), each = 10))
p <- stratified_split(y)
stopifnot(!length(intersect(p$train, p$test)), all(table(y[p$train]) == 7))
m <- classification_metrics(c("No", "No", "Yes", "Yes"), c(.1, .8, .7, .9))
stopifnot(m["recall"] == 1, m["accuracy"] == .75, m["auc"] == .75)
stopifnot(classification_metrics(c("No", "Yes"), c(.5, .5))["auc"] == .5)
d <- as.data.frame(setNames(rep(list(c(1, 3, 5)), length(numeric_features)), numeric_features))
for (nm in category_features) d[[nm]] <- c("A", "B", "A")
s <- fit_schema(d)
te <- d[1, , drop = FALSE]
te$current_age <- NA_real_
te$gender <- "unseen"
x <- apply_schema(te, s)
stopifnot(x$current_age == 3, as.character(x$gender) == "__OTHER__", identical(names(x), feature_names))
cat("fRaud checks passed: stratification, metrics, tied AUC, training schema, unseen levels.\n")
source("prepare.R")
u <- data.frame(id = c("u2", "u1"), current_age = c(30, 40), gender = c("Female", "Male"),
  yearly_income = c("$20,000", "$30,000"), total_debt = c("$0", "$10"), credit_score = c(700, 600), num_credit_cards = c(1, 2))
c <- data.frame(id = c("c1", "c2"), client_id = c("u1", "u2"), credit_limit = c("$2,000", "$3,000"))
t <- data.frame(id = c("t2", "t1"), client_id = c("u2", "u1"), card_id = c("c2", "c1"),
  amount = c("-$10.50", "$11.00"), use_chip = c("Online Transaction", "Chip Transaction"), errors = c("", "PIN"))
l <- data.frame(id = c("t1", "t2"), label = c("No", "Yes"))
j <- join_fraud_sources(t, u, c, l)
stopifnot(identical(j$label, c("Yes", "No")), j$yearly_income[1] == 20000,
  j$amount[1] == -10.5, j$credit_limit[1] == 3000, identical(j$errors, c("No", "Yes")))
fails <- function(x) inherits(tryCatch({force(x); NULL}, error = identity), "error")
stopifnot(fails(join_fraud_sources(t, rbind(u, u[1, ]), c, l)), fails(money_number("oops")))
c$client_id[1] <- "wrong"
stopifnot(fails(join_fraud_sources(t, u, c, l)))
stopifnot(nrow(prepare_legacy_balanced(j, 1)) == 2)
stopifnot(fails(cluster_customers(data.frame(a = c(1, NA)), c("a", "a"), 2)))
stopifnot(fails(classification_metrics(character(0), numeric(0))),
          fails(classification_metrics(c("No", "Yes"), c(.1, .9), c(.4, .5))),
          fails(classification_metrics(c("No", "Yes"), c(.1, .9), NA_real_)))
stopifnot(classification_metrics(c("No", "Yes"), c(.1, .9), Inf)["true_positive"] == 0,
          classification_metrics(c("No", "Yes"), c(.1, .9), -Inf)["recall"] == 1)
cat("Preparation checks passed: keyed joins, currency parsing, duplicate and ownership guards.\n")
