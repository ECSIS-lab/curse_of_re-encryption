# -*- coding: utf-8 -*-

import os
os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

import numpy as np
import tensorflow as tf

# To test trained model
def test(imple):
    tf.random.set_seed(0)
    # Loading pretrained model for test 
    load_model = tf.keras.models.load_model('./model/'+imple+'.h5')

    # Loading and creating data for test
    x_tmp0 = np.load('./dataset/' + imple + '/test/fixed.npy', mmap_mode='r')
    x_tmp1 = np.load('./dataset/' + imple + '/test/random.npy',mmap_mode='r')

    y_tmp0 = np.zeros(5000)
    y_tmp1 = np.ones(5000)

    x_test = np.append(x_tmp0,x_tmp1,axis=0)/256.
    y_test = np.append(y_tmp0,y_tmp1,axis=0)

    # Evaluation
    return load_model.evaluate(x_test,y_test)[1]
