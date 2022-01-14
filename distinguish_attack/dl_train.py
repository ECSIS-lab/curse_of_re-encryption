# -*- coding: utf-8 -*-

import os
import zipfile

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

import numpy as np
import tensorflow as tf

from tensorflow.keras.callbacks import ModelCheckpoint
from tensorflow.keras import optimizers

from sklearn.model_selection import train_test_split


#Loading a dataset for train
class DA_Dataset:
    def __init__(self, imple):
        imple_path = './dataset/'+imple
        if not os.path.exists(imple_path):
            with zipfile.ZipFile(imple_path+'.zip') as z:
                z.extractall(imple_path)

        tmp0 = np.load(imple_path +'/train/fixed.npy',  mmap_mode='r')
        tmp1 = np.load(imple_path +'/train/random.npy', mmap_mode='r')

        wave_num = tmp0.shape[0]
        self.in_size = tmp0.shape[1]

        train_size = wave_num * 2 - 10000
        test_size = 10000

        x_tmp=np.append(tmp0, tmp1, axis=0)/256.
        y_tmp=np.array([0]*wave_num + [1]*wave_num)
        
        self.x_train, self.x_val, self.y_train, self.y_val = train_test_split(x_tmp, y_tmp, train_size = train_size, test_size = test_size, stratify=y_tmp, random_state=0)


# Neural Network Configuration
class DA_Net:
    def __init__(self, in_size, type):
        input_shape = (in_size,1)
        input_w = tf.keras.layers.Input(shape=input_shape)

        # Configuration of a convolutional neural network used to destinguish fixed/random waves of each implementation without masked AES software
        if type == 'cnn':
            w = tf.keras.layers.Conv1D(4, 3, kernel_initializer='he_uniform', padding='same')(input_w)
            w = tf.keras.layers.BatchNormalization()(w)
            w = tf.keras.layers.Activation('selu')(w)
            w = tf.keras.layers.AveragePooling1D(2, strides=2)(w)
            w = tf.keras.layers.Conv1D(4, 3, kernel_initializer='he_uniform', padding='same')(w)
            w = tf.keras.layers.BatchNormalization()(w)
            w = tf.keras.layers.Activation('selu')(w)
            w = tf.keras.layers.AveragePooling1D(2, strides=2)(w)
            w = tf.keras.layers.Conv1D(4, 3, kernel_initializer='he_uniform', padding='same')(w)
            w = tf.keras.layers.BatchNormalization()(w)
            w = tf.keras.layers.Activation('selu')(w)
            w = tf.keras.layers.AveragePooling1D(2, strides=2)(w)

            w = tf.keras.layers.Conv1D(8, 3, kernel_initializer='he_uniform', padding='same')(w)
            w = tf.keras.layers.BatchNormalization()(w)
            w = tf.keras.layers.Activation('selu')(w)
            w = tf.keras.layers.AveragePooling1D(2, strides=2)(w)
            w = tf.keras.layers.Conv1D(8, 3, kernel_initializer='he_uniform', padding='same')(w)
            w = tf.keras.layers.BatchNormalization()(w)
            w = tf.keras.layers.Activation('selu')(w)
            w = tf.keras.layers.AveragePooling1D(2, strides=2)(w)
            w = tf.keras.layers.Conv1D(8, 3, kernel_initializer='he_uniform', padding='same')(w)
            w = tf.keras.layers.BatchNormalization()(w)
            w = tf.keras.layers.Activation('selu')(w)
            w = tf.keras.layers.AveragePooling1D(2, strides=2)(w)
            w = tf.keras.layers.Conv1D(8, 3, kernel_initializer='he_uniform', padding='same')(w)
            w = tf.keras.layers.BatchNormalization()(w)
            w = tf.keras.layers.Activation('selu')(w)
            w = tf.keras.layers.AveragePooling1D(2, strides=2)(w)

        # Configuration of an all-connected layered neural network used to destinguish fixed/random waves of masked AES software
        elif type == 'fc':
            w = tf.keras.layers.Flatten()(input_w)
            w = tf.keras.layers.Dense(32, kernel_initializer='he_uniform')(w)
            w = tf.keras.layers.BatchNormalization()(w)
            w = tf.keras.layers.Activation('selu')(w)
            w = tf.keras.layers.Dense(32, kernel_initializer='he_uniform')(w)
            w = tf.keras.layers.BatchNormalization()(w)
            w = tf.keras.layers.Activation('selu')(w)

        # Same settings for all implementations
        w = tf.keras.layers.Flatten()(w)
        w = tf.keras.layers.Dense(20, kernel_initializer='he_uniform', activation='selu')(w)
        w = tf.keras.layers.BatchNormalization()(w)
        w = tf.keras.layers.Dense(20, kernel_initializer='he_uniform', activation='selu')(w)
        
        output = tf.keras.layers.Dense(1, activation='sigmoid')(w)
        self.model = tf.keras.models.Model(input_w,output)
        self.model.compile(optimizer=optimizers.Adam(lr=0.001), loss='binary_crossentropy', metrics=['accuracy'])

# To train a network 
def train(imple, type, epoch):
    tf.random.set_seed(0)
    
    # Loading dataset
    data = DA_Dataset(imple)

    #Configuration network
    net = DA_Net(data.in_size, type)

    # Configuration for saving the model.
    metric = 'val_accuracy'
    modelCheckpoint = ModelCheckpoint(filepath = './model/'+imple+'.h5',
                                    monitor=metric,
                                    verbose=0,
                                    save_best_only=True,
                                    save_weights_only=False,
                                    mode='max')

    # Running learning
    history = net.model.fit(data.x_train, data.y_train, \
        validation_data=(data.x_val, data.y_val), epochs=epoch, \
        batch_size=1024, callbacks=[modelCheckpoint],verbose=1)
    
    return max(history.history['val_accuracy'])