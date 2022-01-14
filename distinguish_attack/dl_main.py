# -*- coding: utf-8 -*-

import os
import time

import dl_train
import dl_test
import dl_nll_v1
import dl_nll_v2

import tensorflow as tf

os.putenv("CUDA_VISIBLE_DEVICES","0")
physical_devices = tf.config.experimental.list_physical_devices('GPU')
assert len(physical_devices) > 0, "Not enough GPU hardware devices available"
tf.config.experimental.set_memory_growth(physical_devices[0], True) 

# main function
def main():
    # List showing the prepared dataset and the configuration of the network to be used for training.
    imple_list = [("aes_nonprotect_hw",'cnn'),
                ("aes_nonprotect_sw",'cnn'),
                ("keccak_nonprotect_sw",'cnn'),
                ("aes_masked_hw",'cnn'),
                ("aes_masked_sw",'fc'),
                ("ntru_nonprotect_sw",'cnn')]

    # number of epoch
    epoch = 100

    for imple, type in imple_list:
        print('\nimplementation:',imple)
        print('Train & Validation')
        va = dl_train.train(imple, type, epoch)

        print('\nTest')
        ta = dl_test.test(imple)
        print('val accuracy : ' + str(va)[:6] + ' | test accuracy : ' + str(ta)[:6])

        print('\nLikelihood comparison')
        
        # The values shown in the paper were calculated using this code.
        # For details, please refer to README.md.
        #dl_nll_v1.nll(imple)  
        
        # To calculate the exact accuracy, you need to run this code.
        dl_nll_v2.nll(imple)

        time.sleep(5)
        exit()

if __name__ == "__main__":
    main()
