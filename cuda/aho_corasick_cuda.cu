#include <iostream>
#include <vector>
#include <queue>
#include <cuda_runtime.h>

#define ALPHABET_SIZE 26
#define MAX_STATES 5000

using namespace std;

struct AhoCorasick {
    int g[MAX_STATES][ALPHABET_SIZE]; // Граф переходів
    int f[MAX_STATES];                // Функція невдач
    int out[MAX_STATES];              // Вихідні стани
    int states;

    __host__ AhoCorasick() {
        states = 1;
        memset(g, -1, sizeof(g));
        memset(f, 0, sizeof(f));
        memset(out, 0, sizeof(out));
    }

    __host__ void buildMatchingMachine(vector<string> &patterns) {
        for (int i = 0; i < patterns.size(); i++) {
            int currentState = 0;
            for (char c : patterns[i]) {
                int ch = c - 'a';
                if (g[currentState][ch] == -1) {
                    g[currentState][ch] = states++;
                }
                currentState = g[currentState][ch];
            }
            out[currentState] |= (1 << i);
        }

        queue<int> q;
        for (int ch = 0; ch < ALPHABET_SIZE; ch++) {
            if (g[0][ch] != -1) {
                f[g[0][ch]] = 0;
                q.push(g[0][ch]);
            } else {
                g[0][ch] = 0;
            }
        }

        while (!q.empty()) {
            int state = q.front();
            q.pop();
            for (int ch = 0; ch < ALPHABET_SIZE; ch++) {
                if (g[state][ch] != -1) {
                    int failure = f[state];
                    while (g[failure][ch] == -1 && failure != 0)
                        failure = f[failure];

                    f[g[state][ch]] = g[failure][ch];
                    out[g[state][ch]] |= out[f[g[state][ch]]];
                    q.push(g[state][ch]);
                }
            }
        }
    }
};

__global__ void searchKernel(int *g, int *f, int *out, char *text, int textLength, int *results) {
    int tid = blockIdx.x * blockDim.x + threadIdx.x;
    if (tid >= textLength) return;

    int currentState = 0;
    for (int i = tid; i < textLength; i += blockDim.x * gridDim.x) {
        char c = text[i];
        int ch = c - 'a';

        while (g[currentState * ALPHABET_SIZE + ch] == -1 && currentState != 0)
            currentState = f[currentState];

        currentState = g[currentState * ALPHABET_SIZE + ch];
        if (out[currentState] != 0) {
            printf("Match found at state %d\n", currentState); // Debug
            atomicAdd(&results[currentState], 1);
        }
    }
}

int main() {
    vector<string> patterns = {"he", "she", "his", "hers"};
    string text = "ahishers";

    AhoCorasick ac;
    ac.buildMatchingMachine(patterns);

    int *d_g, *d_f, *d_out, *d_results;
    char *d_text;
    int textLength = text.size();

    cudaMalloc(&d_g, sizeof(ac.g));
    cudaMalloc(&d_f, sizeof(ac.f));
    cudaMalloc(&d_out, sizeof(ac.out));
    cudaMalloc(&d_text, textLength * sizeof(char));
    cudaMalloc(&d_results, MAX_STATES * sizeof(int));

    cudaMemcpy(d_g, ac.g, sizeof(ac.g), cudaMemcpyHostToDevice);
    cudaMemcpy(d_f, ac.f, sizeof(ac.f), cudaMemcpyHostToDevice);
    cudaMemcpy(d_out, ac.out, sizeof(ac.out), cudaMemcpyHostToDevice);
    cudaMemcpy(d_text, text.c_str(), textLength * sizeof(char), cudaMemcpyHostToDevice);
    cudaMemset(d_results, 0, MAX_STATES * sizeof(int));

    int threadsPerBlock = 256;
    int blocksPerGrid = (textLength + threadsPerBlock - 1) / threadsPerBlock;
    searchKernel<<<blocksPerGrid, threadsPerBlock>>>(d_g, d_f, d_out, d_text, textLength, d_results);

    int results[MAX_STATES] = {0};
    cudaDeviceSynchronize(); // Debug
    cudaMemcpy(results, d_results, MAX_STATES * sizeof(int), cudaMemcpyDeviceToHost);

    for (int i = 0; i < ac.states; i++) {
        if (results[i] > 0) {
            cout << "Pattern found at state " << i << ": " << results[i] << " times" << endl;
        }
    }

    cudaFree(d_g);
    cudaFree(d_f);
    cudaFree(d_out);
    cudaFree(d_text);
    cudaFree(d_results);

    cudaError_t err = cudaGetLastError();
    if (err != cudaSuccess) {
        cout << "CUDA error: " << cudaGetErrorString(err) << endl;
    } // Debug

    return 0;
}
