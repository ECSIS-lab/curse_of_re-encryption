# -*- coding: utf-8 -*-

import sys
import os
import time
import numpy as np
import tensorflow as tf

from tensorflow.python.client import device_lib
from tensorflow.keras.callbacks import ModelCheckpoint
from tensorflow.keras.datasets import mnist
from tensorflow.keras import optimizers

from sklearn.model_selection import train_test_split


def cnn():
    os.putenv("CUDA_VISIBLE_DEVICES","1")
    physical_devices = tf.config.experimental.list_physical_devices('GPU')
    assert len(physical_devices) > 0, "Not enough GPU hardware devices available"
    tf.config.experimental.set_memory_growth(physical_devices[0], True)
    
    tf.random.set_seed(0)

    imple_list = [("aes_nonprotect_hw",'cnn'),
                 ("aes_nonprotect_sw",'cnn'),
                 ("keccak_nonprotect_sw",'cnn'),
                 ("aes_masked_hw",'cnn'),
                 ("aes_masked_sw",'fc'),
                 ("ntru_nonprotect_sw",'cnn')]
    
    for imple, model in imple_list:
        print('\nimplementation:',imple)

        print('\n====train&val====')

        # param_list = {'aes_nonprotect_hw':(15000,2700,3000,'cnn'),
        #             'ntru_nonprotect_sw':(10000,14500,24500,'cnn'),
        #             'aes_nonprotect_sw':(10000,38600,39100,'cnn'),
        #             'keccak_nonprotect_sw':(10000,60000,61000,'cnn'),
        #             'aes_masked_hw':(495000,0,700,'cnn'),
        #             'aes_masked_sw':(155000,1000,6000,'fc')
        #             }

        #wave_num, start, stop, model = param_list[imple]

        epoch = 100

        
        metric = 'val_accuracy'
        modelCheckpoint = ModelCheckpoint(filepath = './model/'+imple+'.h5',
                                        monitor=metric,
                                        verbose=0,
                                        save_best_only=True,
                                        save_weights_only=False,
                                        mode='max')

        temp0 = np.load('./wave/'+imple+'/train/fixed.npy',  mmap_mode='r')
        temp1 = np.load('./wave/'+imple+'/train/random.npy', mmap_mode='r')

        wave_num = temp0.shape[0]
        in_size = temp0.shape[1]

        train_size = wave_num * 2 - 10000
        test_size = 10000

        x_temp=np.append(temp0, temp1, axis=0)/256.
        y_temp = np.array([0]*wave_num + [1]*wave_num)

        print(np.shape(x_temp))
        print(np.shape(y_temp))
        
        x_train, x_val, y_train, y_val = train_test_split(x_temp, y_temp, train_size = train_size, test_size = test_size, stratify=y_temp, random_state=0)

        print(np.shape(x_train))
        print(np.shape(y_train))
        print(np.shape(x_val))
        print(np.shape(y_val))
        
        input_shape = (in_size,1)
        input_w = tf.keras.layers.Input(shape=input_shape)

        if model == 'cnn':
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

        elif model == 'fc':
            w = tf.keras.layers.Flatten()(input_w)
            w = tf.keras.layers.Dense(32, kernel_initializer='he_uniform')(w)
            w = tf.keras.layers.BatchNormalization()(w)
            w = tf.keras.layers.Activation('selu')(w)
            w = tf.keras.layers.Dense(32, kernel_initializer='he_uniform')(w)
            w = tf.keras.layers.BatchNormalization()(w)
            w = tf.keras.layers.Activation('selu')(w)

        w = tf.keras.layers.Flatten()(w)
        w = tf.keras.layers.Dense(20, kernel_initializer='he_uniform', activation='selu')(w)
        w = tf.keras.layers.BatchNormalization()(w)
        w = tf.keras.layers.Dense(20, kernel_initializer='he_uniform', activation='selu')(w)
        
        output = tf.keras.layers.Dense(1, activation='sigmoid')(w)
        model = tf.keras.models.Model(input_w,output)
        model.compile(optimizer=optimizers.Adam(lr=0.001), loss='binary_crossentropy', metrics=['accuracy'])

        history = model.fit(x_train, y_train, \
        validation_data=(x_val, y_val), epochs=epoch, \
        batch_size=1024, callbacks=[modelCheckpoint],verbose=1)


        print('\n====test====')
        load_model = tf.keras.models.load_model('./model/'+imple+'.h5')

        x_temp0 = np.load('./wave/' + imple + '/test/fixed.npy', mmap_mode='r')
        x_temp1 = np.load('./wave/' + imple + '/test/random.npy',mmap_mode='r')

        y_temp0 = np.zeros(5000)
        y_temp1 = np.ones(5000)

        x_test = np.append(x_temp0,x_temp1, axis=0)/256.
        y_test = np.append(y_temp0,y_temp1,axis=0)

        load_model.evaluate(x_test,y_test)

        time.sleep(5)
        

if __name__ == "__main__":
    cnn()
