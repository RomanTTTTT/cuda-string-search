#include <iostream>
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
    int *h_input, *d_input, *d_output, *h_output;

    h_input = new int[n];
    h_output = new int[(n + THREADS_PER_BLOCK - 1) / THREADS_PER_BLOCK];

    for (int i = 0; i < n; i++) {
        h_input[i] = 1;
    }

    cudaMalloc(&d_input, n * sizeof(int));
    cudaMalloc(&d_output, ((n + THREADS_PER_BLOCK - 1) / THREADS_PER_BLOCK) * sizeof(int));

    cudaMemcpy(d_input, h_input, n * sizeof(int), cudaMemcpyHostToDevice);

    int numBlocks = (n + THREADS_PER_BLOCK - 1) / THREADS_PER_BLOCK;
    sumReduction<<<numBlocks, THREADS_PER_BLOCK>>>(d_input, d_output, n);

    cudaMemcpy(h_output, d_output, numBlocks * sizeof(int), cudaMemcpyDeviceToHost);

    int totalSum = 0;
    for (int i = 0; i < numBlocks; i++) {
        totalSum += h_output[i];
    }

    std::cout << "Total Sum: " << totalSum << std::endl;

    cudaFree(d_input);
    cudaFree(d_output);
    delete[] h_input;
    delete[] h_output;

    return 0;
}
