#include <iostream>
#include <vector>
#include <queue>
#include <string>

#include <cuda_runtime.h>

using namespace std;

#define CHECK_CUDA(call) \
    { \
        cudaError_t err = call; \
        if (err != cudaSuccess) { \
            cerr << "CUDA error at " << __FILE__ << ":" << __LINE__ << " - " \
                 << cudaGetErrorString(err) << endl; \
            exit(1); \
        } \
    }

__global__ void searchKernel(int *d_g, int *d_f, int *d_out, char *d_text, int textLen, int maxC, int *d_results, int numPatterns) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x;
    if (idx >= textLen) return;

    int state = 0;
    for (int i = idx; i < textLen; i++) {
        int ch = d_text[i] - 'a';
        if (ch < 0 || ch >= maxC) {
            state = 0;  // Reset state if character is out of range
            continue;
        }

        while (state >= 0 && d_g[state * maxC + ch] == -1) {
            state = d_f[state];
        }
        state = (state >= 0) ? d_g[state * maxC + ch] : 0;

        if (state >= 0 && d_out[state]) {
            for (int j = 0; j < numPatterns; j++) {
                if (d_out[state] & (1 << j)) {
                    atomicAdd(&d_results[j], 1);
                }
            }
        }
    }
}

class AhoCorasickCUDA {
private:
    static const int MAXC = 26;  // Increased for full alphabet support
    vector<int> out, f, g;
    int states;

public:
    AhoCorasickCUDA() : states(1) {
        g.resize(MAXC, -1);
        out.push_back(0);
        f.push_back(0);
    }

    int getIndex(int state, int ch) { return state * MAXC + ch; }

    void ensureCapacity(int state) {
        int requiredSize = (state + 1) * MAXC;
        if ((int)g.size() < requiredSize) {
            g.resize(requiredSize, -1);
            out.resize(state + 1, 0);
            f.resize(state + 1, 0);
        }
    }

    int buildMatchingMachine(vector<string> &arr) {
        for (int i = 0; i < arr.size(); ++i) {
            int currentState = 0;
            for (char c : arr[i]) {
                int ch = c - 'a';
                if (ch < 0 || ch >= MAXC) continue;
                ensureCapacity(currentState);
                if (g[getIndex(currentState, ch)] == -1) {
                    ensureCapacity(states);
                    g[getIndex(currentState, ch)] = states++;
                }
                currentState = g[getIndex(currentState, ch)];
            }
            out[currentState] |= (1 << i);
        }

        queue<int> q;
        for (int ch = 0; ch < MAXC; ++ch) {
            int index = getIndex(0, ch);
            if (g[index] != -1) {
                f[g[index]] = 0;
                q.push(g[index]);
            } else {
                g[index] = 0;
            }
        }

        while (!q.empty()) {
            int state = q.front();
            q.pop();

            for (int ch = 0; ch < MAXC; ++ch) {
                int index = getIndex(state, ch);
                if (g[index] != -1) {
                    int failure = f[state];
                    while (g[getIndex(failure, ch)] == -1 && failure != 0)
                        failure = f[failure];
                    f[g[index]] = g[getIndex(failure, ch)];
                    out[g[index]] |= out[f[g[index]]];
                    q.push(g[index]);
                }
            }
        }
        return states;
    }

    void searchWords(vector<string> &arr, string text) {
        buildMatchingMachine(arr);
        int textLen = text.size();

        int *d_g, *d_f, *d_out, *d_results;
        char *d_text;
        int numPatterns = arr.size();

        CHECK_CUDA(cudaMalloc(&d_g, g.size() * sizeof(int)));
        CHECK_CUDA(cudaMalloc(&d_f, f.size() * sizeof(int)));
        CHECK_CUDA(cudaMalloc(&d_out, out.size() * sizeof(int)));
        CHECK_CUDA(cudaMalloc(&d_text, textLen * sizeof(char)));
        CHECK_CUDA(cudaMalloc(&d_results, numPatterns * sizeof(int)));

        CHECK_CUDA(cudaMemcpy(d_g, g.data(), g.size() * sizeof(int), cudaMemcpyHostToDevice));
        CHECK_CUDA(cudaMemcpy(d_f, f.data(), f.size() * sizeof(int), cudaMemcpyHostToDevice));
        CHECK_CUDA(cudaMemcpy(d_out, out.data(), out.size() * sizeof(int), cudaMemcpyHostToDevice));
        CHECK_CUDA(cudaMemcpy(d_text, text.c_str(), textLen * sizeof(char), cudaMemcpyHostToDevice));
        CHECK_CUDA(cudaMemset(d_results, 0, numPatterns * sizeof(int)));

        int blockSize = 256;
        int gridSize = (textLen + blockSize - 1) / blockSize;

        searchKernel<<<gridSize, blockSize>>>(d_g, d_f, d_out, d_text, textLen, MAXC, d_results, numPatterns);
        CHECK_CUDA(cudaPeekAtLastError());
        CHECK_CUDA(cudaDeviceSynchronize());

        vector<int> results(numPatterns, 0);
        CHECK_CUDA(cudaMemcpy(results.data(), d_results, numPatterns * sizeof(int), cudaMemcpyDeviceToHost));
        // for (int i = 0; i < numPatterns; i++) {
        //    cout << "Substring: " << arr[i] << " - " << results[i] << endl;
        //}
        for (int i = 0; i < numPatterns; i++) {
          if (results[i] > 0) {
            cout << "1";
          }
          else {
            cout << "0";
          }
        };
        cout << endl;
        CHECK_CUDA(cudaFree(d_g));
        CHECK_CUDA(cudaFree(d_f));
        CHECK_CUDA(cudaFree(d_out));
        CHECK_CUDA(cudaFree(d_text));
        CHECK_CUDA(cudaFree(d_results));
    }
};

int main() {
    vector<string> arr = {"he", "test", "she", "hers", "test2", "his"};
    string text = "ahishers";
    AhoCorasickCUDA ac;
    ac.searchWords(arr, text);
    return 0;
}
