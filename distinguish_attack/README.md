This is the source code for the distinguish attack presented in "Curse of Re-encryption" paper.

In this repository, we targetted
non-protected SHAKE (SHA3) and AES in pqm4 as non-protected software
https://github.com/mupq/pqm4

SASEBO AES hardware as non-protected hardware
http://www.aoki.ecei.tohoku.ac.jp/crypto/

a bit-sliced masked AES software presented in SAC 2016 by Schwabe and Stoffelen as masked software
https://github.com/Ko-/aes-armcortexm

a mased AES hardware based on threshod implementation presented in COSADE 2017 by Ueno, Homma, and Aoki as masked hardware
https://github.com/homma-lab/curse_of_re-encryption (published in this repository)

# Quick Start Guide

1. Clone this repository to get the source code for the experiment.

    ```git clone https://github.com/ECSIS-lab/curse_of_re-encryption.git```

2. Install the modules for the use of our source code dl.py

    ```pip install numpy tensorflow scikit-learn```

3. Let training datasets of fixed and random trace be fixed.npy and random.npy, respectively, and put them at ./wave/_imple_/train with dl.py.
   For example, if you clonde this repository, it is /curse_of_re-encryption/distinguish_attack/wave/_imple_/train
   As dl.py supports the following implementations as _imple_ (after you acquired traces for each implementation), please put it as
  
| Directry name (_imple_) | Target implementation | Details of the waveforms used in DL |
| -------------- | ---- | ----------- |
| aes_nonprotect_hw | Non-protected AES hardware | round2 |
| aes_nonprotect_sw | Non-protected AES software | round1 |
| keccak_nonprotect_sw | Non-protected keccak software | Part of Keccak process | 
| aes_masked_hw | Masked AES hardware |  | 
| aes_masked_sw | Masked AES software | Entire 10 rounds | 

4. As well, let test datasets be fixed.npy and random.npy, and put them at ./wave/_imple_/test.
    
5. Execute dl.py.

   ```python dl.py``` 
   
## Repository structure 
### ./dl.py

The python file contains data-loading, train and test.

### ./requirements.txt

The text file contains the dependencies of the python packages needed to run dl.py.

### ./dataset

Replace this folder with the folder ```dataset``` that you get when you extract the zip file you downloaded from Google Drive.
Download the dataset from the link below.
https://drive.google.com/file/d/17PSrk208qVx61QSO-jRBXMHunNNNGxVY/view?usp=sharing

The dataset in Google Drive is saved as a zip file, so you will need to unzip it before running ```de.py```.
Therefore, when running the code, this directory structure should look like this,

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
  
  
### ./model

The directory where the trained models will be saved after running dl.py.
