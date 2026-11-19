# Check input encoding, fitted results and Shiny predictions.
source("src/fraud_model.R")
path <- Sys.getenv("FRAUD_MODEL_PATH","outputs/model.rds")
if(!file.exists(path)) stop("Train the model before running this integration check.")
b <- readRDS(path)
values <- as.list(b$defaults)
for(n in names(b$levels)) values[[n]] <- b$levels[[n]][1]
x <- encode_observation(values,b)
stopifnot(identical(names(x),b$features),nrow(x)==1)
for(n in setdiff(b$features,names(b$levels))) stopifnot(x[[n]]==values[[n]])
for(n in names(b$levels)) stopifnot(x[[n]]==1)
bad <- values;bad[[names(b$levels)[1]]] <- "unseen value"
stopifnot(inherits(try(encode_observation(bad,b),silent=TRUE),"try-error"))
stopifnot(all(dim(b$confusion) == c(2,2)), sum(b$confusion) == b$test_n,
          all(b$confusion >= 0), all(is.finite(b$metrics)))
app_env <- new.env(parent=globalenv())
sys.source("app.R",app_env)
shiny::testServer(app_env$server, {
 do.call(session$setInputs,c(values,list(classify=1)))
 expected <- as.character(predict(b$model,x,type="response"))
 stopifnot(grepl(paste0("Classification: ",expected),output$prediction,fixed=TRUE))
})
cat("Named predictor encoding, rejection of unknown categories, confusion-matrix integrity and Shiny prediction passed.\n")
