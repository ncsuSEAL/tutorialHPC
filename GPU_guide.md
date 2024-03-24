# How to use the GPUs on Hazel

## What is a GPU?
**Graphics processing units (GPUs)** are processors like CPUs (the "brain" of the computer), but with lots of smaller, more specialized cores. This is why GPUs are often recognized as a great option for parallel processing. They were initially developed to advance graphics and image processing, and over time, have become more generalized and applicable to other highly parallel and demanding use cases (e.g., deep learning, AI, computational modeling, etc). That being said, they are still not as generalized as CPUs; _you'll have to be intentional about pairing your code with the appropriate resources and GPU hardware for your job to execute properly._

The **Compute Unified Device Architecture (CUDA)** is a parallel computing platform created by NVIDIA. It will help you execute a task by spreading the work among thousands of threads that each execute independently on your GPU(s). 

## Selecting the right GPUs, version of CUDA, and compute capability on Hazel
Not all GPUs are created equal. Here's a short summary of the different types of GPUs we have access to and their distinct use cases:

| GPU model 	| Host name(s) 	| GPU power 	| Notes 	|
|---	|---	|---	|---	|
| NVIDIAGeForceGT 	| gpu01, gpu02 	| 6100-6204 	|  	|
| TeslaP100_PCIE_ 	| gpu03, gpu04 	| 157910-172230 	|  	|
| NVIDIAA30 	| gpu07, gpu08 	| 25006-26466 	| errors, as of 03/24/24 	|
| NVIDIAA10 	| gpu09, gpu10, gpu11, gpu12 	| 15579-101170 	|  	|
| NVIDIAA100_SXM4 	| gpu13 	| 316933-360309 	|  most powerful accelerator of the NVIDIA Ampere generation. Use for large neural nets, etc.	|
| NVIDIAL40 	| gpu14, gpu15 	| 110831-125593 	|  	|
| NVIDIAH100PCIe 	| gpu17 	| 42472-344047 	|  	|
| NVIDIAA30 	| gpu05, gpu06 	| 25216-27852 	| errors, as of 03/24/24 	|

For more info about the GPUs, try ```lsload -gpuload``` and ```lshosts | grep gpu```

<more to come soon>
