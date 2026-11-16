library(shiny)
if (!requireNamespace("randomForest", quietly=TRUE)) stop("Run setup.R to install randomForest.")
source("src/fraud_model.R")
model_path <- Sys.getenv("FRAUD_MODEL_PATH","outputs/model.rds")
if (!file.exists(model_path)) stop("Run train.R with the authorized data before launching Shiny.")
bundle <- readRDS(model_path)
customer_path <- Sys.getenv("FRAUD_CUSTOMERS_PATH","data/customers.csv")
customers <- if (file.exists(customer_path)) read.csv(customer_path) else NULL
numeric_fields <- setdiff(bundle$features,names(bundle$levels))
choices <- if (is.null(customers)) character() else names(customers)[vapply(customers,is.numeric,logical(1))]
ui <- fluidPage(titlePanel("fRaud — Transaction analysis"),
 p("Research prototype · balanced transaction sample · human review required"),
 tabsetPanel(
  tabPanel("Transaction model",sidebarLayout(sidebarPanel(
   lapply(numeric_fields,function(n) numericInput(n,gsub("_"," ",n),bundle$defaults[[n]])),
   lapply(names(bundle$levels),function(n) selectInput(n,gsub("_"," ",n),bundle$levels[[n]])),
   actionButton("classify","Evaluate transaction")),mainPanel(
    textOutput("prediction"),p("Forest votes are not calibrated probabilities at natural fraud prevalence."),
    h3("Held-out evaluation"),tableOutput("metrics"),plotOutput("confusion"),plotOutput("importance")))),
  tabPanel("Customer exploration",p("Original unscaled k-means. Clusters describe similarity, not confirmed fraud."),
   selectInput("x","First field",choices,selected="current_age"),
   selectInput("y","Second field",choices,selected="avg_transaction_amount"),
   sliderInput("k","Number of clusters",2,10,3),plotOutput("elbow"),plotOutput("clusters"),tableOutput("means"))))
server <- function(input,output,session) {
 output$metrics <- renderTable(data.frame(metric=names(bundle$metrics),value=round(bundle$metrics,4)))
 prediction <- eventReactive(input$classify,{
  values <- setNames(lapply(bundle$features,function(n) input[[n]]),bundle$features)
  d <- tryCatch(encode_observation(values,bundle),error=function(e) validate(need(FALSE,conditionMessage(e))))
  label <- predict(bundle$model,d,type="response")
  vote <- predict(bundle$model,d,type="prob")[,"Yes"]
  sprintf("Classification: %s · Forest vote for fraud: %.1f%%",as.character(label),100*vote)
 })
 output$prediction <- renderText(prediction())
 output$confusion <- renderPlot({
  m <- bundle$confusion
  image(1:2,1:2,t(m),axes=FALSE,col=colorRampPalette(c("#f3f4ef","#26645b"))(20),xlab="Actual",ylab="Predicted")
  axis(1,1:2,colnames(m));axis(2,1:2,rownames(m))
  for (i in 1:2) for(j in 1:2) text(j,i,m[i,j],col=if(m[i,j]>2000) "white" else "black")
 })
 output$importance <- renderPlot(randomForest::varImpPlot(bundle$model))
 clustered <- reactive({
  validate(need(!is.null(customers),"Add an authorized customers.csv to enable this view."))
  tryCatch(cluster_customers(customers,c(input$x,input$y),input$k),error=function(e) validate(need(FALSE,conditionMessage(e))))
 })
 output$clusters <- renderPlot({r<-clustered();plot(r$data,col=r$fit$cluster,pch=19);points(r$fit$centers,pch=4,cex=2,lwd=2)})
 output$means <- renderTable(clustered()$summary)
 output$elbow <- renderPlot({
  r<-clustered();limit<-min(10,nrow(unique(r$data)))
  values<-sapply(seq_len(limit),function(k) kmeans(r$data,k,iter.max=20,nstart=5)$tot.withinss)
  plot(seq_len(limit),values,type="b",xlab="Clusters",ylab="Within-cluster sum of squares")
 })
}
shinyApp(ui,server)
