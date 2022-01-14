This is the source code for the distinguish attack presented in "Curse of Re-encryption" paper.
More precisely, this repository is designed to reproduce the results of Section 6 of the paper, that is, the evaluation of implementing plaintext-checking oracle from side-channel traces during PRF execution using a neural network.

In this repository, we targetted
non-protected SHAKE (SHA3) and AES in pqm4 as non-protected software
https://github.com/mupq/pqm4

SASEBO AES hardware as non-protected hardware
http://www.aoki.ecei.tohoku.ac.jp/crypto/

a bit-sliced masked AES software presented in SAC 2016 by Schwabe and Stoffelen as masked software
https://github.com/Ko-/aes-armcortexm

a masked AES hardware based on threshod implementation presented in COSADE 2017 by Ueno, Homma, and Aoki as masked hardware
https://github.com/homma-lab/curse_of_re-encryption (published in this repository)

# Quick Start Guide

1. Clone this repository to get the source code for the experiment.

    ```git clone https://github.com/ECSIS-lab/curse_of_re-encryption.git```

2. Install the modules for the use of our source code dl.py

    ```pip install numpy tensorflow scikit-learn tqdm```

3. Let training and test datasets of fixed and random trace be fixed.npy and random.npy, respectively, and put them at ./dataset/_imple_/train(or test) with dl.py.
   Please refer to ./dataset section of Repository structure below for detailed placement instructions.
   As dl.py supports the following implementations as _imple_ (after you acquired traces for each implementation), please put it as
  
| Directry name (_imple_) | Target implementation | Details of the waveforms used in DL |
| -------------- | ---- | ----------- |
| aes_nonprotect_hw | Non-protected AES hardware | Round2 |
| aes_nonprotect_sw | Non-protected AES software | Round1 |
| keccak_nonprotect_sw | Non-protected keccak softwRre | Part of Keccak process | 
| aes_masked_hw | Masked AES hardware | Round10 | 
| aes_masked_sw | Masked AES software | Entire 10 rounds | 

4. Execute dl_main.py.

   ```python dl_main.py``` 
   
## How to view the execution results

After executing dl_main.py, you can find the NN loss and accuracy for training, validation, and test as follows:

```
$ python dl_main.py

implementation: aes_nonprotect_hw
Train & Validation
/# Learning progress is displayed as a progress bar.
Epoch 1/100
30/30 [==============================] - 4s 40ms/step - loss: 0.6226 - accuracy: 0.6678 - val_loss: 0.8554 - val_accuracy: 0.5000
...
30/30 [==============================] - 1s 17ms/step - loss: 0.0016 - accuracy: 0.9995 - val_loss: 0.0091 - val_accuracy: 0.9971

Test
313/313 [==============================] - 2s 4ms/step - loss: 0.0064 - accuracy: 0.9984
# Accuracy of both validation and test 
val accuracy : 0.9990 | test accuracy : 0.9983

Likelihood comparison

# Note that the calculation will take some time.
```

where, 'loss' and 'accuracy' are for training, 'val_loss' and 'val_accuracy' are for validation at the epoch during Train & Validation.
Test loss and accuracy are found under 'Test'.
Then, the validation accuracy and test accuracy are summarized like 'val accuracy : 0.9990 | test accuracy : 0.9983'.
Test accuracy corresponds to Table 6, fisrt paragraph, Section 6.2.

After evaluating the NN accuracy and loss, the accuracy of plaintext-checking oracle using multiple-trace with likelihood comparison is evaluated as follows:

```
Accuracy of negative log-likelihood accuracy
Trace num : 1 | Nll test accuracy : 0.9053
Trace num : 2 | Nll test accuracy : 0.9726
...

# Note that the seed value is different from the value calculated in the paper, 
# so each value may be calculated differently from the one published in the paper.
```

where the PC oracle accuracy (i.e., NLL test accuracy) is reported for each number of traces (Trace num).
This corresponds to second paragraph, Section 6.2.


## Repository structure 
### ./dl_main.py

This python file is main function.



### ./dl_train.py

The python file contains data-loading and train.



### ./dl_test.py

The python file contains test.



### ./dl_nll_v1.py

The python file calculates the plaintext-checking oracle accuracy using the likelihood comparison.

The values shown in the paper were calculated using this code.

To avoid underflow, we added a small value (like a clipping balue) to the output probability of NN.



### ./dl_nll_v2.py

The python file Calculates the log likelihood test accuracy using this Python file.

This is an update of dl_nll_v1.py to avoid underflow using a log softmax instead of adding small values.



### ./requirements.txt

The text file contains the dependencies of the python packages needed to run dl.py.



### ./dataset

Replace this folder with the folder ```dataset``` that you get when you extract the zip file you downloaded from Google Drive.
You can find the dataset from the link below:
https://drive.google.com/file/d/17PSrk208qVx61QSO-jRBXMHunNNNGxVY/view?usp=sharing

The dataset in Google Drive is saved as a zip file, so you will need to unzip it before running ```de.py```.
Therefore, when running the code, this directory structure should be

```
dataset/
  ├ aes_nonprotect_sw/
  │  ├ test/
  │  │  ├ fixed.npy
  │  │  └ random.npy
  │  └ train/
  │     ├ fixed.npy
  │     └ random.npy
  │
  ├ aes_nonprotect_hw/
  │  ├ test/
  │  │  ├ fixed.npy
  │  │  └ random.npy
  │  └ train/
  │     ├ fixed.npy
  │     └ random.npy
  ...
```
  
  
  
### ./model

The directory stores the trained models after running dl.py.
