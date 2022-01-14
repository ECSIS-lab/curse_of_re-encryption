# -*- coding: utf-8 -*-

import os
import math

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '3'

import tqdm
import numpy as np
import tensorflow as tf
from sklearn.model_selection import train_test_split

#Calculation log likelihood comparison
def nll(imple):
    tf.random.set_seed(0)

    # loading pretrained model for calculating log likelihood comparison
    load_model = tf.keras.models.load_model('./model/'+imple+ '.h5')
    logits_model = tf.keras.Model(inputs = load_model.input,outputs = load_model.get_layer('dense_2').output)

    data_num = 5000
    stop = 30
    iterate  =5000

    # Loading and creating data
    x_tmp0 = np.load('./dataset/' + imple + '/test/fixed.npy', mmap_mode='r')[:data_num]/256.
    x_tmp1 = np.load('./dataset/' + imple + '/test/random.npy',mmap_mode='r')[:data_num]/256.

    y_tmp0 = np.zeros(data_num)
    y_tmp1 = np.ones(data_num)

    for i in range(0,stop):
        rate_1 = 0
        rate_0 = 0
        for j in tqdm.tqdm(range(iterate), leave=False):
            sum1_1=0
            sum1_0=0
            sum0_1=0
            sum0_0=0
            _, x0, _, _ = train_test_split(x_tmp0, y_tmp0, test_size = i+1,shuffle=True,random_state=j)
            _, x1, _, _ = train_test_split(x_tmp1, y_tmp1, test_size = i+1,shuffle=True,random_state=j)
            
            # Prediction 
            l0 = logits_model.predict(x0)
            l1 = logits_model.predict(x1)

            for k in range(i+1):
                sum0_0 += tf.math.log_sigmoid(l0[k][0])
                sum0_1 += tf.math.log_sigmoid(-l0[k][0])
                sum1_0 += tf.math.log_sigmoid(-l1[k][0])
                sum1_1 += tf.math.log_sigmoid(l1[k][0])
            if sum1_1>sum1_0:
                rate_1 += 1
            if sum0_1<sum0_0:
                rate_0 += 1
        result_nll = (rate_1+rate_0) / (2*iterate)
        print('Trace num : ' + str(i+1) + ' | Nll test accuracy : ' + str(result_nll)[:6])

