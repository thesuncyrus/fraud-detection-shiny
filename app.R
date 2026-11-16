# Run train.R first, then shiny::runApp('.') from this directory.
# FRAUD_MODEL_PATH and FRAUD_CUSTOMERS_PATH can override the default local files.
library(shiny)
if (!requireNamespace("randomForest", quietly = TRUE)) stop("Install randomForest.")
source("functions.R")
model_path <- Sys.getenv("FRAUD_MODEL_PATH", "outputs/model.rds")
if (!file.exists(model_path)) stop("Run train.R before starting the application.")
bundle <- readRDS(model_path)
customer_path <- Sys.getenv("FRAUD_CUSTOMERS_PATH", "data/customers.csv")
customers <- if (file.exists(customer_path)) read.csv(customer_path) else NULL
numeric_choices <- if (is.null(customers)) {
  character(0)
} else {
  setdiff(names(customers)[vapply(customers, is.numeric, logical(1))], c("id", "client_id"))
}
labels <- c(
  current_age = "Age", yearly_income = "Yearly income", total_debt = "Total debt",
  credit_score = "Credit score", num_credit_cards = "Number of cards", amount = "Transaction amount", credit_limit = "Credit limit"
)
ui <- fluidPage(
  titlePanel("fRaud"),
  p("Research prototype for transaction classification and customer exploration."),
  tabsetPanel(
    tabPanel("Transaction model", sidebarLayout(
      sidebarPanel(
        lapply(numeric_features, function(nm) numericInput(nm, labels[[nm]], bundle$schema$medians[[nm]])),
        lapply(category_features, function(nm) selectInput(nm, gsub("_", " ", nm), setdiff(bundle$schema$levels[[nm]], "__OTHER__"))),
        actionButton("classify", "Evaluate transaction")
      ),
      mainPanel(
        h3("Model output"), textOutput("prediction"),
        p("Scores reflect a model trained on balanced data and are not calibrated fraud probabilities."),
        h3("Held-out evaluation"), tableOutput("metrics")
      )
    )),
    tabPanel(
      "Customer exploration",
      p("Clustering describes similarity, not confirmed fraud. Both selected fields are standardized."),
      selectInput("x", "First field", numeric_choices), selectInput("y", "Second field", numeric_choices, selected = tail(numeric_choices, 1)),
      sliderInput("k", "Clusters", 2, 10, 3), plotOutput("clusters"), tableOutput("means")
    )
  )
)
server <- function(input, output, session) {
  output$metrics <- renderTable(data.frame(metric = names(bundle$metrics)[1:6], value = round(bundle$metrics[1:6], 4)))
  prediction <- eventReactive(input$classify, {
    vals <- lapply(feature_names, function(nm) input[[nm]])
    names(vals) <- feature_names
    d <- as.data.frame(vals, stringsAsFactors = FALSE)
    validate(need(all(vapply(d[, numeric_features], function(v) length(v) == 1 && is.finite(v), logical(1))), "Enter a finite number for every numeric field."))
    validate(need(all(d[setdiff(numeric_features, "amount")] >= 0), "Non-transaction fields cannot be negative."))
    x <- apply_schema(d, bundle$schema)
    s <- as.numeric(predict(bundle$model, x, type = "prob")[, "Yes"])
    sprintf("Classification: %s | Forest vote for fraud: %.1f%%", if (s >= .5) "Flag for review" else "Not flagged", 100 * s)
  })
  output$prediction <- renderText(prediction())
  clustered <- reactive({
    validate(
      need(!is.null(customers), "Place customers.csv in data/ to enable clustering."),
      need(input$x != input$y, "Choose two different fields.")
    )
    tryCatch(cluster_customers(customers, c(input$x, input$y), input$k), error = function(e) validate(need(FALSE, conditionMessage(e))))
  })
  output$clusters <- renderPlot({
    r <- clustered()
    plot(r$data, col = r$cluster, pch = 19, xlab = input$x, ylab = input$y)
  })
  output$means <- renderTable(clustered()$summary)
}
shinyApp(ui, server)
