#include <bits/stdc++.h>
using namespace std;

class AhoCorasick {
private:
    static const int MAXC = 26;
    vector<int> out;
    vector<int> f;
    vector<int> g;
    int states;

public:
    AhoCorasick() : states(1) {
        g.resize(MAXC, -1);
        out.push_back(0);
        f.push_back(0);
    }

    int getIndex(int state, int ch) {
        return state * MAXC + ch;
    }

    void ensureCapacity(int state) {
        int requiredSize = (state + 1) * MAXC;
        if ((int)g.size() < requiredSize) {
            g.resize(requiredSize, -1);
            out.resize(state + 1, 0);
            f.resize(state + 1, 0);
        }
    }

    int buildMatchingMachine(string arr[], int k) {
        for (int i = 0; i < k; ++i) {
            const string &word = arr[i];
            int currentState = 0;

            for (char c : word) {
                int ch = c - 'a';
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

    int findNextState(int currentState, char nextInput) {
        int ch = nextInput - 'a';
        while (g[getIndex(currentState, ch)] == -1 && currentState != 0)
            currentState = f[currentState];
        return g[getIndex(currentState, ch)];
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
