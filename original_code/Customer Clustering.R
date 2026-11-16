setwd("C:/Users/Owner/Desktop/College/Spring 2025/MGMT 389/Customer Clustering")

customers = read.csv("customers.csv", header = T, sep = ",")

library(shiny)
library(ggplot2)
library(dplyr)
library(rsconnect)

palette(c("#E41A1C", "#377EB8", "#4DAF4A", "#984EA3",
          "#FF7F00", "#FFFF33", "#A65628", "#F781BF", "#999999"))


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
    #tabPanel(
      #"Classification" 
      # Insert Classification Model IO here
    #),
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

