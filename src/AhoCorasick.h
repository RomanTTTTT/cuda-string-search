#ifndef AHO_CORASICK_H
#define AHO_CORASICK_H

#include <iostream>
#include <vector>
#include <queue>
#include <unordered_map>

using namespace std;

class AhoCorasick {
private:
    static const int MAXC = 26;
    vector<int> out;
    vector<int> f;
    vector<int> g;
    int states;

    int getIndex(int state, int ch);
    void ensureCapacity(int index);

public:
    AhoCorasick();
    int buildMatchingMachine(string arr[], int k);
    int findNextState(int currentState, char nextInput);
    void searchWords(string arr[], int k, string text, unordered_map<string, int> &resultDict);
};

#endif // AHO_CORASICK_H
