#FILE:    mnist_example.py (python version of mnist_example.R)
#AUTHOR:  Karsten Suhre
#DATE:    6 Jan 2021
#PURPOSE: evaluate usage of python with tensorflow and keras to do AI
#MODIF:   

# run the mnist character recognition example in python
# see https://hub.packtpub.com/distributed-tensorflow-multiple-gpu-server/

import tensorflow as tf

print("Running mnist character recognition in python")
print("using tensorflow version " + tf.__version__)
print("Num GPUs Available: ", len(tf.config.list_physical_devices('GPU')))
print(tf.config.list_physical_devices('GPU'))

print("getting the data")
(train_images, train_labels), (test_images, test_labels) = tf.keras.datasets.mnist.load_data()

print("train_images.shape")
print(train_images.shape)

print("defining the model")
network = tf.keras.Sequential()

print("adding layers")
network.add(tf.keras.layers.Dense(1024, activation='relu', input_shape=(28 * 28,)))
network.add(tf.keras.layers.Dropout(rate = 0.4))
network.add(tf.keras.layers.Dense(256, activation='relu', input_shape=(28 * 28,)))
network.add(tf.keras.layers.Dropout(rate = 0.3))
network.add(tf.keras.layers.Dense(64, activation='relu', input_shape=(28 * 28,)))
network.add(tf.keras.layers.Dropout(rate = 0.2))
network.add(tf.keras.layers.Dense(10, activation='softmax'))

print("compiling the model")
network.compile(optimizer='rmsprop',
    loss='categorical_crossentropy',
    metrics=['accuracy'])

train_images = train_images.reshape((60000, 28 * 28))
train_images = train_images.astype('float32') / 255
test_images = test_images.reshape((10000, 28 * 28))
test_images = test_images.astype('float32') / 255

train_labels = tf.keras.utils.to_categorical(train_labels)
test_labels = tf.keras.utils.to_categorical(test_labels)

print("fitting the model")
network.fit(train_images, train_labels, 
  epochs=10, batch_size=256,
  validation_split=0.2)

print("evaluating the model")
test_loss, test_acc = network.evaluate(test_images, test_labels)

print('test_acc:', test_acc)
