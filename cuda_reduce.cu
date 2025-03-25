#include <iostream>
#include <vector>
#include <cuda_runtime.h>

#define THREADS_PER_BLOCK 256

__global__ void sumReduction(int *input, int *output, int n) {
    __shared__ int sharedData[THREADS_PER_BLOCK];

    int tid = threadIdx.x + blockIdx.x * blockDim.x;
    int local_tid = threadIdx.x;

    sharedData[local_tid] = (tid < n) ? input[tid] : 0;
    __syncthreads();

    for (int stride = blockDim.x / 2; stride > 0; stride /= 2) {
        if (local_tid < stride) {
            sharedData[local_tid] += sharedData[local_tid + stride];
        }
        __syncthreads();
    }

    if (local_tid == 0) {
        output[blockIdx.x] = sharedData[0];
    }
}

int main() {
    int n = 1024;
    std::vector<int> h_input(n, 1);
    int numBlocks = (n + THREADS_PER_BLOCK - 1) / THREADS_PER_BLOCK;
    std::vector<int> h_output(numBlocks);

    int *d_input, *d_output;
    cudaMalloc(&d_input, n * sizeof(int));
    cudaMalloc(&d_output, numBlocks * sizeof(int));

    cudaMemcpy(d_input, h_input.data(), n * sizeof(int), cudaMemcpyHostToDevice);

    sumReduction<<<numBlocks, THREADS_PER_BLOCK>>>(d_input, d_output, n);
    cudaDeviceSynchronize();

    cudaMemcpy(h_output.data(), d_output, numBlocks * sizeof(int), cudaMemcpyDeviceToHost);

    int totalSum = 0;
    for (int i = 0; i < numBlocks; i++) {
        totalSum += h_output[i];
    }

    std::cout << "Total Sum: " << totalSum << std::endl;

    cudaFree(d_input);
    cudaFree(d_output);

    return 0;
}
