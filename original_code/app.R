setwd("C:/Users/Owner/Desktop/College/Spring 2025/MGMT 389/MGMT389 Project")

customers = read.csv("customers.csv", header = T, sep = ",")
processed_data <- read.csv("Balanced_Processed.csv", header = T, sep = ",")

library(shiny)
library(ggplot2)
library(dplyr)
library(data.table)
library(caret)
library(randomForest)

palette(c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3",
          "#FF7F00", "#FFFF33", "#A65628", "#F781BF", "#999999"))

processed_data$id = NULL
processed_data$label <- as.factor(processed_data$label)
processed_data <- processed_data %>%
  mutate_if(is.character, ~ as.numeric(as.factor(.)))

set.seed(123)
trainIndex <- createDataPartition(processed_data$label, p = 0.7, list = FALSE)
train_data <- processed_data[trainIndex, ]
test_data <- processed_data[-trainIndex, ]
model <- randomForest(label ~ ., data = train_data)
preds <- predict(model, newdata = test_data, type = "response")
confMatrix <- confusionMatrix(as.factor(preds), as.factor(test_data$label))
conf_matrix_plot <- as.data.frame(confMatrix$table)

ui = fluidPage(
  tags$head(
    tags$style(HTML("
      .title {
        font-size: 32px;
        text-align: center;
      }
    "))
  ),
  titlePanel(
    tags$div(class = "title", "fRaud: An R-Shiny Application To Identify Financial Transaction Fraud"),
    "fRaud"
  ),
  tabsetPanel(
    tabPanel(
      "Fraud Detection Model",
      sidebarLayout(
        sidebarPanel(
          tags$h3("Test Out sample Transaction Data"),
          htmlOutput("Instructions"),
          textInput("Age", label = "Age"),
          textInput("Gender", label = "Gender"),
          textInput("Yearly_Income", label = "Yearly Income"),
          textInput("Total_Debt", label = "Total Debt"),
          textInput("Credit_Score", label = "Credit Score"),
          textInput("Num_Credit_Cards", label = "Number of Credit Cards"),
          textInput("Amount", label = "Transaction Amount"),
          textInput("Use_Chip", label = "Transaction Type"),
          textInput("Error", label = "Error"),
          textInput("Credit_Limit", "Credit Limit"),
          actionButton("classify", label = "Classify"),
          textOutput("classification_result")
          ),
        mainPanel(
          plotOutput("cm"),
          plotOutput("ImpPlot")
    ))),
    tabPanel(
      "Customer Clustering",
      sidebarLayout(
        sidebarPanel(
          selectInput(inputId = "col1",
                        label = "Choose x variable",
                        choices = names(customers),
                        selected = "current_age"),
          selectInput(inputId = "col2",
                      label = "Choose y variable",
                      choices = names(customers),
                      selected = "avg_transaction_amount")
        ),
        mainPanel(
          plotOutput("wcss")
        )
      ),
      sidebarLayout(
        sidebarPanel(
          sliderInput(inputId = "num_clusters",
                      label = "Enter the number of Clusters",
                      min = 2,
                      max = 10,
                      value = 3,
                      step = 1)
        ),
        mainPanel(
          tags$div(style = "display: flex; flex-direction: column; align-items: center;",
                   plotOutput("clusters"),
                   tags$h3("Average Metrics per Cluster"),
                   tags$div(style = "display: flex; justify-content: center;",
                            tags$style(HTML("
                .shiny-table {
                  width: 80%; 
                  font-size: 16px; 
                }
              ")),
                            tableOutput("Avg_metrics")))
        )
      )
    )
  )
)

server = function(input, output) {
  
  output$Instructions = renderUI({
    HTML(paste(
      "Enter Gender:<br>",
      "1 for Female<br>",
      "2 for Male<br>",
      "<br>",
      "Enter Transaction Type:<br>",
      "1 for Chip Transaction<br>",
      "2 for Online Transaction<br>",
      "3 for Swipe Transaction<br>",
      "<br>",
      "Enter Error<br>",
      "1 for No<br>",
      "2 for Yes<br><br>",
      "Errors include:<br>",
      "Technical Glitch, Bad Expiration, Bad Card Number, Insufficienmt Balance,",
      "Bad PIN, Bad CVV, Bad Zipcode, or a combination of these<br>"
    ))
  })
  
  saved_text <- reactiveVal("")
  
  observeEvent(input$classify, {
    ob = as.data.frame(cbind(as.numeric(input$Age), as.numeric(input$Gender), as.numeric(input$Yearly_Income), as.numeric(input$Total_Debt),
                             as.numeric(input$Credit_Score), as.numeric(input$Num_Credit_Cards), as.numeric(input$Amount), 
                             as.numeric(input$Use_Chip), as.numeric(input$Error), as.numeric(input$Credit_Limit), as.numeric(input$classify)))
    names(ob) = names(test_data)
    pred = predict(model, newdata = ob, type = "response")
    saved_text(as.character(pred))
  })
  
  output$classification_result = renderText({
    saved_text()
  })
  
  output$cm = renderPlot({
    ggplot(conf_matrix_plot, aes(x = Reference, y = Prediction, fill = Freq)) +
      geom_tile(color = "white") +
      geom_text(aes(label = Freq), vjust = 1) +
      scale_fill_gradient(low = "white", high = "steelblue") +
      labs(title = "Confusion Matrix", x = "Actual", y = "Predicted") +
      theme_minimal()
  })
  
  output$ImpPlot = renderPlot({
    varImpPlot(model)
  })
  
  # subsetting cluster data
  cluster_data <- reactive({
    customers[, c(input$col1, input$col2)]
  })
  
  # reactively calculating cluster results
  cluster_results = reactive({
    kmeans(cluster_data(), input$num_clusters, iter.max = 20, nstart = 5)
  })
  
  # mean_cluster
  mean_cluster = reactive({
    cluster_data = cluster_data()
    cluster_data$id = cluster_results()$cluster
    mean_cluster = cluster_data %>% group_by(id) %>%
      summarize(
        col1 = mean(get(input$col1)),
        col2 = mean(get(input$col2))
      )
    names(mean_cluster) = c("cluster_id", input$col1, input$col2)
    return(mean_cluster)
  })
  
  # wcss plot
  output$wcss = renderPlot({
    wcss = vector()
    for (i in 1:10)
      wcss[i] <- kmeans(cluster_data(), i, iter.max = 20, nstart = 5)$tot.withinss

    n_cluster <- seq(1,10)
    plot_data <- data.frame(n_cluster,wcss)

    ggplot(plot_data, aes(n_cluster, wcss)) +
      geom_point() + 
      geom_path() +
      scale_x_continuous(breaks = seq(1,10,1)) + 
      labs(x = "Number of Clusters", 
           y = "WCSS")
  })
  
  # clusters plot
  output$clusters = renderPlot({
    par(mar = c(5.1, 4.1, 0, 1))
    plot(cluster_data(),
        col = cluster_results()$cluster,
        pch = 20, cex = 3)
    points(cluster_results()$centers, pch = 4, cex = 4, lwd = 4)
  })


  output$Avg_metrics = renderTable({
    mean_cluster()
  })
}

shinyApp(ui = ui, server = server)




