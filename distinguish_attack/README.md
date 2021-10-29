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

識別攻撃のための深層学習モデルを作成・評価するためには，以下の手順に従ってください．

1. このレポジトリをクローンし，実験用のソースコードを取得します．

    ```git clone https://github.com/ECSIS-lab/curse_of_re-encryption.git```

2. 実験用のソースコードdl.pyが必要とするモジュールをインストールします．

    ```pip install numpy tensorflow scikit-learn```

3. 固定およびランダムの波形をそれぞれfixed.npy，random.npyとし，dl.pyと同じディレクトリ内の./wave/_imple_/trainに配置してください．
   例として，このレポジトリをクローンした場合は，/curse_of_re-encryption/distinguish_attack/wave/_imple_/trainが配置場所となります．
   dl.py内では _imple_ として以下の実装による波形が指定されていますので，それぞれ入手し，配置してください．
  
  | ディレクトリ名 (_imple_) | 内容 |
| -------------- | ---- |
| aes_nonprotect_hw | AESの未対策ハードウェア実装 |
| keccak_nonprotect_sw | ケチャックの未対策ソフトウェア実装 |
| aes_masked_hw | AESのマスク対策ハードウェア実装 |
| aes_masked_sw | AESのマスク対策ソフトウェア実装 | 
| ntru_nonprotect_sw| NTRUの未対策ソフトウェア実装 |


4. モデル性能評価用の固定およびランダムの波形を同様にfixed.npy，random.npyとし，./wave/_imple_/testに配置してください．
    
5. dl.pyを実行します．

   ```python dl.py``` 
