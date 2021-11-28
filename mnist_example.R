#FILE:    mnist_example.R
#AUTHOR:  Karsten Suhre
#DATE:    3 Jan 2019
#PURPOSE: evaluate usage of R with tensorflow and keras to do AI
#MODIF:   

# inspired by https://tensorflow.rstudio.com

rm(list=ls())
library(keras)

# test example from https://tensorflow.rstudio.com/keras/
mnist <- dataset_mnist()
x_train <- mnist$train$x
y_train <- mnist$train$y
x_test <- mnist$test$x
y_test <- mnist$test$y

# reshape
x_train <- array_reshape(x_train, c(nrow(x_train), 784))
x_test <- array_reshape(x_test, c(nrow(x_test), 784))

# rescale
x_train <- x_train / 255
x_test <- x_test / 255

y_train <- to_categorical(y_train, 10)
y_test <- to_categorical(y_test, 10)

# Defining the Model
model <- keras_model_sequential() 

# We begin by creating a sequential model and then adding layers using the pipe (%>%) operator
model %>% 
  layer_dense(units = 1024, activation = 'relu', input_shape = c(784)) %>% 
  layer_dropout(rate = 0.4) %>% 
  layer_dense(units = 256, activation = 'relu', input_shape = c(784)) %>% 
  layer_dropout(rate = 0.3) %>% 
  layer_dense(units = 64, activation = 'relu') %>%
  layer_dropout(rate = 0.2) %>%
  layer_dense(units = 10, activation = 'softmax')

# Next, compile the model with appropriate loss function, optimizer, and metrics:
model %>% compile(
  loss = 'categorical_crossentropy',
  optimizer = optimizer_rmsprop(),
  metrics = c('accuracy')
)

# print the model config
print(summary(model))

# Use the fit() function to train the model for N epochs using batches of batch_size images
history <- model %>% fit(
  x_train, y_train, 
  epochs = 10, batch_size = 2048, 
  #callbacks = callback_tensorboard("logs/run_a"),
  validation_split = 0.2
)

plot(history)

# Evaluate the model's performance on the test data:
eval = model %>% evaluate(x_test, y_test) 
print(eval)

