#ifndef AHO_CORASICK_CUDA_H
#define AHO_CORASICK_CUDA_H

#include <vector>
#include <string>
#include <cuda_runtime.h>

#define ALPHABET_SIZE 26
#define MAX_STATES 5000  // Максимальна кількість станів автомата

class AhoCorasickCUDA {
public:
    int g[MAX_STATES][ALPHABET_SIZE]; // Граф переходів
    int f[MAX_STATES];                // Функція невдач
    int out[MAX_STATES];              // Вихідні стани
    int states;

    AhoCorasickCUDA();
    void buildMatchingMachine(const std::vector<std::string> &patterns);
    void searchWordsCUDA(const std::string &text);
};

// CUDA Kernel для пошуку
__global__ void searchKernel(int *g, int *f, int *out, char *text, int textLength, int *results);

#endif // AHO_CORASICK_CUDA_H
