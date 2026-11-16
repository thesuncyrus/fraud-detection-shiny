# Named-column replacement for Balanced_Processed.R's positional SQL extraction.
# This raw-source route is fixture-tested. The complete original raw tables were
# not supplied; published model results instead use supplied Balanced_Processed.csv.
money_number <- function(x) {
  if (is.numeric(x)) return(x)
  raw <- trimws(as.character(x)); cleaned <- gsub("[$,]", "", raw)
  value <- suppressWarnings(as.numeric(cleaned))
  if (any(!is.na(raw) & nzchar(raw) & is.na(value))) stop("Unparseable monetary value.")
  value
}
assert_key <- function(d, key) {
  if (!key %in% names(d) || anyNA(d[[key]]) || any(!nzchar(as.character(d[[key]]))) || anyDuplicated(d[[key]])) stop(paste("Invalid unique key:", key))
}
join_fraud_sources <- function(transactions, users, cards, labels) {
  for (x in list(transactions, users, cards, labels)) assert_key(x, "id")
  required <- function(d, names) if (!all(names %in% colnames(d))) stop("Missing raw source fields.")
  required(transactions, c("client_id", "card_id", "amount", "use_chip", "errors"))
  required(users, c("current_age", "gender", "yearly_income", "total_debt", "credit_score", "num_credit_cards"))
  required(cards, c("credit_limit")); required(labels, "label")
  # Join only labeled transactions; record exclusions in the CLI audit.
  index <- match(transactions$id, labels$id)
  t <- transactions[!is.na(index), , drop = FALSE]
  label <- labels$label[index[!is.na(index)]]
  if (!nrow(t) || anyNA(label) || any(!label %in% c("No", "Yes"))) stop("Invalid fraud labels.")
  ui <- match(t$client_id, users$id); ci <- match(t$card_id, cards$id)
  if (anyNA(ui) || anyNA(ci)) stop("Labeled transaction has no matching user or card.")
  if ("client_id" %in% names(cards) && any(as.character(cards$client_id[ci]) != as.character(t$client_id))) stop("Card ownership mismatch.")
  d <- data.frame(label = label, id = t$id,
    users[ui, c("current_age", "gender", "yearly_income", "total_debt", "credit_score", "num_credit_cards")],
    amount = t$amount, use_chip = trimws(t$use_chip),
    errors = ifelse(is.na(t$errors) | !nzchar(trimws(t$errors)), "No", "Yes"),
    credit_limit = cards$credit_limit[ci], row.names = NULL, check.names = FALSE)
  for (nm in c("current_age", "yearly_income", "total_debt", "credit_score", "num_credit_cards", "amount", "credit_limit")) d[[nm]] <- money_number(d[[nm]])
  d$gender <- trimws(d$gender)
  stopifnot(nrow(d) == nrow(t), !anyDuplicated(d$id))
  d
}
prepare_legacy_balanced <- function(d, per_class = 12500L, seed = 123L) {
  # Reconstruct the historical balanced experiment, not a natural-prevalence test.
  if (length(per_class) != 1 || !is.finite(per_class) || per_class < 1 || per_class != as.integer(per_class)) stop("Invalid per_class.")
  if (anyNA(d$label) || any(!d$label %in% c("No", "Yes"))) stop("Invalid labels.")
  set.seed(seed)
  ids <- unlist(lapply(c("Yes", "No"), function(label) {
    found <- which(d$label == label)
    if (length(found) < per_class) stop("Insufficient rows in a class.")
    found[sample.int(length(found), per_class)]
  }))
  d[ids, , drop = FALSE]
}
if (sys.nframe() == 0) {
  args <- commandArgs(trailingOnly = TRUE)
  if (length(args) < 2) stop("Usage: Rscript prepare.R raw-folder output.csv")
  if (!requireNamespace("jsonlite", quietly = TRUE)) stop("Install jsonlite.")
  read_raw <- function(file) read.csv(file.path(args[1], file), stringsAsFactors = FALSE, check.names = FALSE, colClasses = "character")
  td <- read_raw("transactions_data.csv"); ud <- read_raw("users_data.csv"); cd <- read_raw("cards_data.csv")
  target <- jsonlite::fromJSON(file.path(args[1], "train_fraud_labels.json"))$target
  if (is.null(names(target))) stop("Expected named target mapping in labels JSON.")
  labels <- data.frame(id = names(target), label = as.character(unlist(target)), stringsAsFactors = FALSE)
  joined <- join_fraud_sources(td, ud, cd, labels)
  balanced <- prepare_legacy_balanced(joined)
  dir.create(dirname(args[2]), recursive = TRUE, showWarnings = FALSE)
  write.csv(balanced, args[2], row.names = FALSE)
  write.csv(data.frame(stage = c("raw_transactions", "labeled_joined", "balanced"), rows = c(nrow(td), nrow(joined), nrow(balanced))), paste0(args[2], ".audit.csv"), row.names = FALSE)
}
