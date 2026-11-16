# Optional integration check after training; set FRAUD_MODEL_PATH when needed.
source("app.R")
stopifnot(inherits(bundle$model, "randomForest"))
shiny::testServer(server, {
  vals <- as.list(bundle$schema$medians)
  for (nm in category_features) vals[[nm]] <- setdiff(bundle$schema$levels[[nm]], "__OTHER__")[1]
  do.call(session$setInputs, vals)
  session$setInputs(classify = 1)
  stopifnot(grepl("Forest vote", output$prediction))
  if (!is.null(customers) && length(numeric_choices) >= 2) {
    session$setInputs(x = numeric_choices[1], y = numeric_choices[2], k = 3)
    stopifnot(nrow(clustered()$summary) == 3)
  }
})
cat("Shiny integration passed: named input schema, prediction and optional clustering.\n")
