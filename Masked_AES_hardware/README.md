# Masked AES hardware

Masked AES hardware based on 2-share threshold implementation, corresponding to COSADE 2017 paper by Rei Ueno, Naofumi Homma, and Takafumi Aoki
This hardware is used for the experiment in "Curse of Re-encryption" paper.

 About this architecture:
 This architecture completes one block encryption within 219 clock cycles.
 The I/O and behavior of this arcthiecture basically follow the SASEBO AES core at
 http://www.aoki.ecei.tohoku.ac.jp/crypto/
 except for the number of encryption clock cylces and trigger.
 Although the original architecture presented in the above paper has byte-serial I/O for data and key,
 we employ a 128-bit wise I/O for the ease of trace acquisition.
 The initial masking is performed immediately after data input, and unmasking is performed just before data output.
 This arcthiecture does NOT protect the round key and key scheduling datapath, as it causes no DPA leakage.
 (However it of course causes leakage for the TVLA or input distinguishing attack unless the key is fixed.)
 Randomness is generated using four 128-bit XOR-shifts (each of which generates 32-bit randomness per clock)
 with a hard-coded seed.
 The linear mappings in this architecture is optimized using a technique named "multiplicative-offset."
 See https://ieeexplore.ieee.org/document/8922779 .
 To use this AES core, you require a non-masked S-box hardware (for mudule "GF_INV_8") provided at
 https://faculty.nps.edu/drcanrig/pub/index.html .
 If you use this non-masked S-box, you MUST follow the terms and considtions specified for its use.
