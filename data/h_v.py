# -*- coding: utf-8 -*-

import numpy as np

from sklearn.model_selection import train_test_split

import tensorflow as tf

from tensorflow.python.client import device_lib
from tensorflow.keras.callbacks import ModelCheckpoint
from tensorflow.keras.datasets import mnist
from tensorflow.keras import optimizers

def cnn():

    il = ["aes_nonprotect_hw",
             "ntru_nonprotect_sw",
             "aes_nonprotect_sw",
             "keccak_nonprotect_sw",
             "aes_masked_hw",
             "aes_masked_sw"]
             
    param_list = {'aes_nonprotect_hw':(15000,2700,3000,'cnn'),
                  'ntru_nonprotect_sw':(10000,14500,24500,'cnn'),
                  'aes_nonprotect_sw':(10000,38600,39100,'cnn'),
                  'keccak_nonprotect_sw':(10000,60000,61000,'cnn'),
                  'aes_masked_hw':(495000,0,700,'cnn'),
                  'aes_masked_sw':(155000,100,6000,'fc')
                  }

    for imple in il:
        wave_num, start, stop, model = param_list[imple]

        temp0 = np.load('./wave/' + imple + '/merge/' + str(0).zfill(3)+'.npy', mmap_mode='r')[:wave_num+5000,start:stop]
        temp1 = np.load('./wave/' + imple + '/merge/' + str(1).zfill(3)+'.npy', mmap_mode='r')[:wave_num+5000,start:stop]

        np.save("./wave/" +  imple + "/train/fixed", temp0[:wave_num])
        np.save("./wave/" +  imple + "/train/random", temp1[:wave_num])

        np.save("./wave/" +  imple + "/test/fixed", temp0[wave_num:])
        np.save("./wave/" +  imple + "/test/random", temp1[wave_num:])


if __name__ == "__main__":
    cnn()