# FPGA Term Project - Simple TPU
Team members: <`E24076459蕭又瑜`><`E24071069陳志瑜`><`E24073037鍾震`>
## Introduction
CNN has been widely used in many image-related machine learning algorithms due to its high accuracy for image recognition. Convolution and fully-connected layers are two essential components for CNN. Our goal is to design a simple TPU to accelerate them.
![](https://i.imgur.com/HTzKhct.png)


## Algorithm
### Target model for our TPU: CNN
- **Convolutional Layers**: Feature extraction
- **Fully Connected Layers**: Classification
![](https://i.imgur.com/BklQNyV.png)

### 2D Convolutional layers
- The core building block of CNN
- Each filter (kernel) is convolved across the width and height of the input
- It compute the **dot product** between the filter entries and the input
- It produces a 2-dimensional activation map (or say, output feature map) of that filter
- Dot product implies similarity between input image and the filter
- Different filters extract different features from the input image and pass the result to the next layer
![](https://i.imgur.com/sD3qwcP.png)


### GEMM
- GEMM stands for GEneral Matrix to Matrix Multiplication
- It is a single, well-understood function that gives us a very clear path to optimizating for speed and power usage
![](https://i.imgur.com/gqZHjHB.png)

> ref: https://petewarden.com/2015/04/20/why-gemm-is-at-the-heart-of-deep-learning/ 

### GEMM on Fully-Connected Layers
- FC layers are the calssic neural network layer
- It is the easiest to start with how GEMM is used for the computation
- The are `k` input values in the input feature map (or say, number of neurons) and `n` output neurons, so there are totally `k * n` weights
![](https://i.imgur.com/JrbF1cv.png)
![](https://i.imgur.com/if6Nu8o.png)

### GEMM for Convolutional Layers
- We can think of each kernel to be a 2D array of numbers, whose shape is `Height` by `Width` by `Channel`
- The convolution produces the output by taking a number of kernels of weights and applying them across the image

| ![](https://i.imgur.com/apX8AfK.png) | ![](https://i.imgur.com/m4FQYSd.png) |
| -------- | -------- |

- Here we use a function called `im2col`
  - `im2col` stands for image-to-column
  - Given kernel size and the stride of a convolutional layer, `im2col` convert the 3D image into a 2D array that we can treat like a matrix
![](https://i.imgur.com/WQ1pDEG.png)

- Also, we have to flatten the kernels, where `k` is the number of values in each patch so it is kernel `Width` * `Height` * `Depth`
- The resulting matrix will be *number of Patches* high and *Number of Kerenels* wide
![](https://i.imgur.com/SdsGCWx.png)

## Architecture
### Dataflow of GEMM
- We can first construct the DFD of computing a output matrix entry directly form the definition
  ![](https://i.imgur.com/sapzRKK.png)
  
![](https://i.imgur.com/4asOMQy.png)
- Problems
  - Long data path
  - Waste of area
  - Not scalable for very large `k`
  
### Iterative Decomposition
- Through step-by-stop execution, we can accomplish resource sharing
- We need to fetch a row from A and a column from B every time we compute an entry in C
#### Before iterative decomposition
![](https://i.imgur.com/O50ALN1.png)

#### After iterative decomposition
![](https://i.imgur.com/xuPQkkx.png)
- Problems
  - A row from A does dot product to every column in B, so it is fetched from memory `n` times.
  - On the other hand, a column in B is fetched from memory `m` times
  - This could result in bad data reuse rate

### Why systolic architecture?
- We can think of these components as
  - **Memory**: heart
  - **Data**: blood
  - **PE's**: cells
![](https://i.imgur.com/7rKdA6i.png)
> "If a structrue can truly be decomposed into a few types of simple substructures or building blocks, which are used repetitively with simple interfaces, great savings can be achieved." - H.T. Kung, ref: http://www.eecs.harvard.edu/~htk/publication/1982-kung-why-systolic-architecture.pdf 

### How GEMM can utilize systolic architecture
#### Use 1D systolic array
- Now every row in A only need to be fetched from memory once, which improves the data reuse rate
![](https://i.imgur.com/17Mk1vx.png)

#### Use 2D systolic array
- Now every row in A and B only need to be fetched from memory once
- This yields even better data reuse rate
![](https://i.imgur.com/GR8S4uS.png)
- Final confitureation
  - Using a 8-by-8 2D systolic array

### What if the output matrix C has a dimension larger than (8, 8)?
- Here we take an output matrix of (10, 10) for example
- We had to divide the computation into 4 batches, each doing a region of 8-by-8
- However, PE utalization rate can decrease when processing the batch near margin
  - Those PE's who are not in the dimension will be idling
  - **Tradeoff!!**
![](https://i.imgur.com/rllNJsS.png)





## Implementation
### Software
#### Target model
In this project, the target model is a simple **CNN for MNIST dataset**, which is trained with tensoflow framework. Our goal is to design a TPU with high compatibility, so RGB-input model is also acceptable. Here is our model summary.
![](https://i.imgur.com/kEOVOM7.png)
#### Im2col function
Two functions are designed to do the transformation between matrix and image:
1. Define **im2col** to turn RGB figures and multi-channel wieghts into matrices.
2. Define **col2im** to reshape the matrices back, so we can do activation and maxpooling with correct space relations.
![](https://i.imgur.com/t4RtmdU.png)
#### Eliminate Tensoflow dependency
Although Convolution and Fully connect will be accelerated on TPU in PL, PS still have to deal all the other functions like: activation, pooling, softmax… Also, Keras framework is not supported on ARM CPU. To eliminate the dependency, **model's weights are extracted and re-built it on ZYNQ processor without importing tensorflow library.** We also have to use self made CONV and FC function to do algorithm simulation, ensuring the correctness before HW design. Also, all of them have an fixed-point version.
![](https://i.imgur.com/ofXfmGB.png)
![](https://i.imgur.com/5vtc1Jp.png)
#### Fixed point quantization
It’s easier to consider floating point number as fixed point for hardware design. However, a bad quantization might decrease accuracy seriously. The follwing shows Some experiments with different fraction bit length for our model.
![](https://i.imgur.com/wbdDwfw.png)
We found that setting fraction bit length to 4~8 would yield a better result. Finally, **8 is chosen.**

A simple model with only one convolution layer is used to visualize our quantization results.
![](https://i.imgur.com/SydBiau.png)
### Hardware
#### CDMA
Since our matrices size are quite large (at least 16kB each), the heavy data transmission may become the bottleneck.

Our solution:
**AXI Central DMA (CDMA)** provides high-bandwidth Direct Memory Access (DMA) between a memory-mapped source address and a memory-mapped destination address using the AXI4 protocol. In our project it's used to **connect ZYNQ Processor DDR3 High Peformance Pin and Block RAM**.  Also, AXI Interconnection module is introdced to help us deal with Master/Slave connection.
![](https://i.imgur.com/vLZuPtq.png)
#### Memory map layout
The following figures show our memory map layout for 3 I/O buffer (global_buffer) of TPU.
![](https://i.imgur.com/cHVMLa1.png)
After computation below, 3 of 64KB buffers are implemented.
![](https://i.imgur.com/1GzCLq9.png)
Note that each word length in PL is 128-bits.
#### Infer Block RAM & DSP module
1. global_buffer
I/O buffers for TPU to buffer input matrics and output matrix, can utilize block RAM. We have two type I/O buffers, inferred with the coding style provided by Xillinx.
* source_buffer : [Simple Dual-Port Asymmetric RAM When Read is wider than Write](https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis/Dual-Port-Asymmetric-RAM-When-Read-is-Wider-than-Write-Verilog)
![](https://i.imgur.com/dxKAXGj.png)

* target_buffer : [Simple Dual-Port Asymmetric RAM When Write is wider than Read](https://docs.xilinx.com/r/en-US/ug901-vivado-synthesis/Simple-Dual-Port-Asymmetric-RAM-When-Write-is-Wider-than-Read-Verilog)
![](https://i.imgur.com/eFjv20h.png)

Total size of block memory on PYNQ is 630KB:
630KB x 11.43 % = 72KB / IO buffer
The difference between 64KB and 72KB is due to ECC. 


2. PE
![](https://i.imgur.com/hcnsZH2.png)
The essential componets for TPU including mac operation, can utilize DSP Module. We infer it by descripting HW architecture of [DSP48E1](https://docs.xilinx.com/v/u/en-US/ug479_7Series_DSP48E1). Also, multiplier’s pipelined register is considered.
![](https://i.imgur.com/3nQxHLD.png)
#### Block design
**“CDMA + TDP BRAM” version**
![](https://i.imgur.com/UovfrSF.png)
**“SDP Asymmetric BRAM” version**
![](https://i.imgur.com/wSEUpY4.png)
## Results

### Uitilization
* one 8 x 8 Systolic Array = DSP48E1 x 64
* three 64KB global_buffer = RAMB36E1 x 16 x 3
* three BRAM controller
* AXI interconnection
* ZYNQ Processor
### Demostration
This simulation shows that our TPU works fine.
C++ code generated pattern : 
![](https://i.imgur.com/O4PtbOj.png)
HDL waveform:
![](https://i.imgur.com/sGoP8Es.png)

Unfortunately, on PYNQ, results from our system cannot match the one from SW.
![](https://i.imgur.com/UBo9snC.png)
We find that the output after convolution is all zero.
![](https://i.imgur.com/FDiVzDt.png)




### Discussion
* **How to make our system work ?**
Bram address calculated by python have to be checked more closely.
* **Data transmission should transmit 32 bits or 128 bits each time?**
This is our first time to deal asymmetric-memory-access case. We should dive deeper to reaserch the details.
* **How to Improve our system?**
Improve software api to support more CNN models: more activation functions, cut large data into batches.





