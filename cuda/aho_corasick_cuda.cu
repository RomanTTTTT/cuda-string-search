#include <cuda_runtime.h>
#include "aho_corasick_cuda.h"
#include <iostream>
#include <queue>

__global__ void searchAhoCorasickKernel(const char* text, int text_length, TrieNode** d_trie, int* results) {
    int idx = threadIdx.x + blockIdx.x * blockDim.x;
    if (idx >= text_length) return;

    TrieNode* state = d_trie[0];

    for (int i = idx; i < text_length; i++) {
        while (state != nullptr && state->children.find(text[i]) == state->children.end())
            state = state->fail_link;

        if (state == nullptr) state = d_trie[0];
        else state = state->children[text[i]];#include <iostream>
#include <vector>
#include <queue>
#include <cuda_runtime.h>

#define ALPHABET_SIZE 26
#define MAX_STATES 5000  // Максимальна кількість станів автомата

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

// === Кернел для паралельного пошуку ===
__global__ void searchKernel(int *g, int *f, int *out, char *text, int textLength, int *results) {
    int tid = threadIdx.x + blockIdx.x * blockDim.x;
    if (tid >= textLength) return;

    int currentState = 0;
    for (int i = tid; i < textLength; i += gridDim.x * blockDim.x) {
        char c = text[i];
        int ch = c - 'a';

        while (g[currentState * ALPHABET_SIZE + ch] == -1 && currentState != 0)
            currentState = f[currentState];

        currentState = g[currentState * ALPHABET_SIZE + ch];
        if (out[currentState] != 0) {
            atomicAdd(&results[currentState], 1);
        }
    }
}

int main() {
    vector<string> patterns = {"he", "she", "his", "hers"};
    string text = "ahishers";

    AhoCorasick ac;
    ac.buildMatchingMachine(patterns);

    // === Копіюємо структуру на GPU ===
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

    // === Запускаємо CUDA-кернел ===
    int threadsPerBlock = 256;
    int blocksPerGrid = (textLength + threadsPerBlock - 1) / threadsPerBlock;
    searchKernel<<<blocksPerGrid, threadsPerBlock>>>(d_g, d_f, d_out, d_text, textLength, d_results);

    // === Отримуємо результати ===
    int results[MAX_STATES] = {0};
    cudaMemcpy(results, d_results, MAX_STATES * sizeof(int), cudaMemcpyDeviceToHost);

    // Виводимо результати
    for (int i = 0; i < ac.states; i++) {
        if (results[i] > 0) {
            cout << "Pattern found at state " << i << ": " << results[i] << " times" << endl;
        }
    }

    // === Звільняємо пам’ять ===
    cudaFree(d_g);
    cudaFree(d_f);
    cudaFree(d_out);
    cudaFree(d_text);
    cudaFree(d_results);

    return 0;
}


        if (state->output != -1)
            atomicAdd(&results[i], 1);
    }
}

void buildAhoCorasick(TrieNode* root, const std::vector<std::string>& patterns) {
    for (const auto& pattern : patterns) {
        TrieNode* node = root;
        for (char ch : pattern) {
            if (node->children.find(ch) == node->children.end())
                node->children[ch] = new TrieNode();
            node = node->children[ch];
        }
        node->output = 1;
    }

    std::queue<TrieNode*> q;
    root->fail_link = root;

    for (auto& [ch, node] : root->children) {
        node->fail_link = root;
        q.push(node);
    }

    while (!q.empty()) {
        TrieNode* cur = q.front();
        q.pop();

        for (auto& [ch, node] : cur->children) {
            TrieNode* fail = cur->fail_link;
            while (fail != root && fail->children.find(ch) == fail->children.end())
                fail = fail->fail_link;

            if (fail->children.find(ch) != fail->children.end())
                node->fail_link = fail->children[ch];
            else
                node->fail_link = root;

            q.push(node);
        }
    }
}

void searchAhoCorasickCUDA(const std::string& text, TrieNode* root, std::vector<int>& results) {
    int text_length = text.size();

    char* d_text;
    cudaMalloc(&d_text, text_length);
    cudaMemcpy(d_text, text.c_str(), text_length, cudaMemcpyHostToDevice);

    TrieNode** d_trie;
    cudaMalloc(&d_trie, sizeof(TrieNode*));
    cudaMemcpy(d_trie, &root, sizeof(TrieNode*), cudaMemcpyHostToDevice);

    int* d_results;
    cudaMalloc(&d_results, text_length * sizeof(int));
    cudaMemset(d_results, 0, text_length * sizeof(int));

    int threadsPerBlock = 256;
    int blocksPerGrid = (text_length + threadsPerBlock - 1) / threadsPerBlock;

    searchAhoCorasickKernel<<<blocksPerGrid, threadsPerBlock>>>(d_text, text_length, d_trie, d_results);

    cudaMemcpy(results.data(), d_results, text_length * sizeof(int), cudaMemcpyDeviceToHost);

    cudaFree(d_text);
    cudaFree(d_trie);
    cudaFree(d_results);
}
