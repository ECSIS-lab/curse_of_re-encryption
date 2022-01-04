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
  
| Directry name (_imple_) | Target implementation | Expected location of the traces |
| -------------- | ---- | ----------- |
| aes_nonprotect_hw | Non-protected AES hardware | |
| keccak_nonprotect_sw | Non-protected keccak software | | 
| aes_masked_hw | Masked AES hardware | | 
| aes_masked_sw | Masked AES software | | 

4. As well, let test datasets be fixed.npy and random.npy, and put them at ./wave/_imple_/test.
    
5. Execute dl.py.

   ```python dl.py``` 
   
## Repository structure 
### ./dl.py

The python file contains data-loading, train and test.

### ./requirements.txt

The text file contains the dependencies of the python packages needed to run dl.py.

### ./dataset

The directory containing the datasets used in this distinguish attack. 
It's in .zip format, so you need to unzip it before running ```python dl.py```.

### ./model

The directory where the trained models will be saved after running dl.py.
