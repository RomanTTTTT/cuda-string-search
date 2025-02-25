#include <bits/stdc++.h>
using namespace std;

class PatternMatcher {
private:
    struct TrieNode {
        unordered_map<char, TrieNode*> children;
        TrieNode* failure = nullptr;
        vector<int> output;
    };
    TrieNode* root;
    vector<string> markers;

public:
    PatternMatcher() {
        root = new TrieNode();
    }

    void Init(const vector<string>& patterns) {
        markers = patterns;
        buildTrie();
        buildFailureLinks();
    }

    void buildTrie() {
        for (size_t i = 0; i < markers.size(); ++i) {
            TrieNode* node = root;
            for (char c : markers[i]) {
                if (!node->children.count(c)) {
                    node->children[c] = new TrieNode();
                }
                node = node->children[c];
            }
            node->output.push_back(i);
        }
    }

    void buildFailureLinks() {
        queue<TrieNode*> q;
        for (auto& [c, child] : root->children) {
            child->failure = root;
            q.push(child);
        }

        while (!q.empty()) {
            TrieNode* node = q.front(); q.pop();
            for (auto& [c, child] : node->children) {
                TrieNode* failure = node->failure;
                while (failure && !failure->children.count(c)) {
                    failure = failure->failure;
                }
                child->failure = (failure) ? failure->children[c] : root;
                child->output.insert(child->output.end(), child->failure->output.begin(), child->failure->output.end());
                q.push(child);
            }
        }
    }

    vector<bool> Search(const string& text) {
        vector<bool> result(markers.size(), false);
        TrieNode* node = root;

        for (char c : text) {
            while (node && !node->children.count(c)) {
                node = node->failure;
            }
            node = (node) ? node->children[c] : root;
            for (int index : node->output) {
                result[index] = true;
            }
        }
        return result;
    }
};

int main() {
    string genome = "ahishers";
    vector<string> markers = {"he", "test", "she", "hers", "test2", "his"};

    PatternMatcher pm;
    pm.Init(markers);
    vector<bool> result = pm.Search(genome);

    cout << "arr[bool] = {";
    for (size_t i = 0; i < result.size(); ++i) {
        cout << result[i];
        if (i != result.size() - 1) cout << ", ";
    }
    cout << "}" << endl;

    return 0;
}
