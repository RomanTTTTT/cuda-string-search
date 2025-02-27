#include <bits/stdc++.h>
using namespace std;

class AhoCorasick {
private:
    static const int MAXS = 500;
    static const int MAXC = 26; //ch
    int out[MAXS];
    int f[MAXS];
    int g[MAXS][MAXC]; //ch

public:
    AhoCorasick() {
        memset(out, 0, sizeof out);
        memset(g, -1, sizeof g);
        memset(f, -1, sizeof f);
    }

    int buildMatchingMachine(string arr[], int k) {
        int states = 1;

        for (int i = 0; i < k; ++i) {
            const string &word = arr[i];
            int currentState = 0;

            for (char c : word) {
                int ch = c - 'a';
                if (g[currentState][ch] == -1)
                    g[currentState][ch] = states++;
                currentState = g[currentState][ch];
            }
            out[currentState] |= (1 << i);
        }

        for (int ch = 0; ch < MAXC; ++ch)
            if (g[0][ch] == -1)
                g[0][ch] = 0;

        queue<int> q;

        for (int ch = 0; ch < MAXC; ++ch) {
            if (g[0][ch] != 0) {
                f[g[0][ch]] = 0;
                q.push(g[0][ch]);
            }
        }

        while (!q.empty()) {
            int state = q.front();
            q.pop();

            for (int ch = 0; ch < MAXC; ++ch) {
                if (g[state][ch] != -1) {
                    int failure = f[state];
                    while (g[failure][ch] == -1)
                        failure = f[failure];
                    failure = g[failure][ch];
                    f[g[state][ch]] = failure;
                    out[g[state][ch]] |= out[failure];
                    q.push(g[state][ch]);
                }
            }
        }
        return states;
    }

    int findNextState(int currentState, char nextInput) {
        int ch = nextInput - 'a';
        while (g[currentState][ch] == -1)
            currentState = f[currentState];
        return g[currentState][ch];
    }

    void searchWords(string arr[], int k, string text, unordered_map<string, int> &resultDict) {
        buildMatchingMachine(arr, k);
        int currentState = 0;

        for (int i = 0; i < k; ++i) {
            resultDict[arr[i]] = 0;
        }

        for (char c : text) {
            currentState = findNextState(currentState, c);
            if (out[currentState] == 0)
                continue;

            for (int j = 0; j < k; ++j) {
                if (out[currentState] & (1 << j)) {
                    resultDict[arr[j]]++;
                }
            }
        }
    }
};

int main() {
    string arr[] = {"he", "test", "she", "hers", "test2", "his"};
    string text = "ahishers";
    int k = sizeof(arr) / sizeof(arr[0]);
    unordered_map<string, int> resultDict;

    AhoCorasick ac;
    ac.searchWords(arr, k, text, resultDict);

    for (const auto &entry : resultDict) {
        cout << "Substring: " << entry.first << " - " << entry.second << endl;
    }

    return 0;
}
